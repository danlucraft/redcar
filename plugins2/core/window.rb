
require 'gtk2'

module Redcar
  class Window < Gtk::Window
    extend FreeBASE::StandardPlugin
    
    def self.load(plugin) #:nodoc:
      Hook.register :new_tab
      Hook.register :close_tab
      Hook.register :focus_tab
      
      Sensitive.register(:tab, [:open_window, :new_tab, :close_tab]) do
        win and win.tabs.length > 0
      end
      
      plugin.transition(FreeBASE::LOADED)
    end
    
    def self.start(plugin) #:nodoc:
      App.new_window
      Keymap.push_onto(self, "Global")
      
      plugin.transition(FreeBASE::RUNNING)
    end
    
    def self.stop(plugin) #:nodoc:
      App.close_all_windows(false)
      Keymap.remove_from(self, "Global")
      
      Hook.clear_plugin_hooks(self)
      
      plugin.transition(FreeBASE::LOADED)
    end
    
    attr_reader(:notebooks_panes, :previous_tab, :gtk_menubar, 
                :focussed_gtk_widget, :gtk_speedbar)
    
    # Do not call this directly, use App#new_window instead. 
    # Creates a new Redcar window. 
    def initialize
      super()#("Redcar")
      title = "Redcar"
      @notebooks_panes = {}
      @focussed_tab = nil
      @focussed_gtk_widget = nil
      build_widgets
      MenuDrawer.draw_menus(self)
      connect_signals
      show_initial_widgets
    end
    
    # Close this Redcar window.
    def close
      App.close_window(self, true)
    end
    
    # Returns an array of all the Panes in the Window.
    def panes
      @notebooks_panes.values.sort_by {|p| p.object_id }
    end
    
    # Unifies all the Panes into one.
    def unify_all
      while panes.length > 1
        panes.first.unify
      end
    end
    
    # Equivalent to calling Pane#new_tab on the currently
    # focussed Pane.
    def new_tab(tab_class, *args)
      t = if focussed_tab
            focussed_tab.pane.new_tab(tab_class, *args)
          else
            panes.first.new_tab(tab_class, *args)
          end
      t
    end
    
    # Returns an array of all tabs in the Window.
    def tabs
      panes.map {|pane| pane.tabs }.flatten
    end
    
    def collect_tabs(klass)
      tabs.select {|t| t.is_a? klass}
    end
    
    define_method_bracket :tab do |id|
      if id.is_a? String
        tabs.find{|t| t.label.text == id}
      end
    end
    
    # Returns an array of all active tabs (all tabs at the 
    # forefront of their Panes).
    def active_tabs
      panes.map {|p| p.active_tab}.compact
    end
    
    # Returns the currently focussed Tab in the Window.
    def focussed_tab
      if @focussed_tab
        @focussed_tab
      else
        active_tabs.first
      end
    end
    
    def split_horizontal(pane) #:nodoc:
      split_pane(:horizontal, pane)
    end
    
    def split_vertical(pane) #:nodoc:
      split_pane(:vertical, pane)
    end

    def close_tab(tab) #:nodoc:
      if tab.pane
        nb = tab.pane.gtk_notebook
        unless nb.destroyed?
          nb.remove_page(nb.page_num(tab.gtk_nb_widget))
          Tab.widget_to_tab.delete tab.gtk_nb_widget
          if nb.n_pages > 0
            update_focussed_tab(Tab.widget_to_tab[nb.page_child])
          else
            if nexttab = active_tabs.first
              nexttab.gtk_tab_widget.grab_focus
              update_focussed_tab(nexttab)
            end
          end
        end
        Hook.trigger :close_tab, tab
      else
        raise "trying to close tab with no pane: #{tab.label.text}"
      end      
    end
    
    def unify(pane) #:nodoc:
      panes_container = pane.gtk_notebook.parent
      unless panes_container.class == Gtk::HBox
        other_side = panes_container.children.find do |p|
          p != pane.gtk_notebook
        end
        panes_container.remove(pane.gtk_notebook)
        panes_container.remove(other_side)
        if [Gtk::HPaned, Gtk::VPaned].include? other_side.class
          other_tabs = collect_tabs_from_dual(other_side)
        else
          other_tabs = @notebooks_panes[other_side].tabs
          @notebooks_panes.delete other_side
        end
        container_of_container = panes_container.parent
        other_panes = other_tabs.map{|t| t.pane}.uniq
        other_tabs.each do |tab|
          tab.pane.move_tab(tab, pane)
        end
        if container_of_container.class == Gtk::HBox
          container_of_container.remove panes_container
          container_of_container.pack_start pane.gtk_notebook
        else
          if container_of_container.child1 == panes_container
            container_of_container.remove panes_container
            container_of_container.add1 pane.gtk_notebook
          else
            container_of_container.remove panes_container
            container_of_container.add2 pane.gtk_notebook
          end
        end
      end
    end
    
    def debug_print_widgets(gtk_widget=self, indent=0) #:nodoc:
      puts " "*indent + gtk_widget.class.to_s
      if gtk_widget.respond_to? :children
        gtk_widget.children.each do |gtk_child|
          debug_print_widgets gtk_child, indent+2
        end
      end
    end
    
    def update_focussed_tab(tab) #:nodoc:
      Hook.trigger :focus_tab
      @previously_focussed_tab = @focussed_tab
      @focussed_tab = tab
    end
    
    private

    def collect_tabs_from_dual(dual)
      [dual.child1, dual.child2].map do |child|
        if child.class == Gtk::Notebook
          @notebooks_panes[child].tabs
        else
          collect_tabs_from_dual(child)
        end
      end.flatten
    end
    
    def split_pane(whichway, pane)
      case whichway
      when :vertical
        dual = Gtk::VPaned.new
      when :horizontal
        dual = Gtk::HPaned.new
      end
      new_pane = Pane.new self
      @notebooks_panes[new_pane.gtk_notebook] = new_pane
      panes_container = pane.gtk_notebook.parent
      if panes_container.class == Gtk::HBox
        panes_container.remove(pane.gtk_notebook)
        dual.add(new_pane.gtk_notebook)
        dual.add(pane.gtk_notebook)
        panes_container.pack_start(dual)
      else
        if panes_container.child1 == pane.gtk_notebook # (on the left or top)
          panes_container.remove(pane.gtk_notebook)
          dual.add(new_pane.gtk_notebook)
          dual.add(pane.gtk_notebook)
          panes_container.add1(dual)
        else
          panes_container.remove(pane.gtk_notebook)
          dual.add(new_pane.gtk_notebook)
          dual.add(pane.gtk_notebook)
          panes_container.add2(dual)
        end
      end
      dual.show
      dual.position = 200
    end
    
    def notebook_to_pane(nb)
      @notebooks_panes[nb]
    end
    
    def connect_signals
      signal_connect("destroy") do
        self.close
      end
      signal_connect('key-release-event') do |gtk_widget, gdk_eventkey|
        continue = Keymap.process(gdk_eventkey)
        # falls through to Gtk widgets if nothing handles it
        continue
      end
      
      # Everytime the focus changes, check to see if we have changed tabs.
      signal_connect('set-focus') do |_, gtk_widget, _|
        @focussed_gtk_widget = gtk_widget
        until gtk_widget == nil or 
            Tab.widget_to_tab.keys.include? gtk_widget or
            @notebooks_panes.keys.include? gtk_widget
          gtk_widget = gtk_widget.parent
        end
        if gtk_widget
          if Tab.widget_to_tab[gtk_widget]
            update_focussed_tab(Tab.widget_to_tab[gtk_widget])
          elsif @notebooks_panes.keys.include? gtk_widget
            gtk_notebook = @notebooks_panes.keys.find{|nb| nb == gtk_widget}
            pageid = gtk_notebook.page
            gtk_nb_widget = gtk_notebook.get_nth_page(pageid)
            update_focussed_tab(Tab.widget_to_tab[gtk_nb_widget])
          end
        end
      end
    end
    
    def build_widgets
      set_size_request(800, 600)
      @gtk_menubar = Gtk::MenuBar.new 
      gtk_table = Gtk::Table.new(1, 4, false)
      bus["/gtk/window/table"].data = gtk_table
      bus["/gtk/window/menubar"].data = @gtk_menubar
      gtk_table.attach(@gtk_menubar,
                       # X direction            # Y direction
                       0, 1,                    0, 1,
                       Gtk::EXPAND | Gtk::FILL, 0,
                       0,                       0)
      gtk_toolbar = Gtk::Toolbar.new
      bus["/gtk/window/toolbar"].data = gtk_toolbar
      gtk_table.attach(gtk_toolbar,
                       # X direction            # Y direction
                       0, 1,                    1, 2,
                       Gtk::EXPAND | Gtk::FILL, 0,
                       0,                       0)
      gtk_project = Gtk::Button.new("PROJECT")
      gtk_panes_box = Gtk::HBox.new
      gtk_edit_view = Gtk::HBox.new
      bus["/gtk/window/editview"].data = gtk_edit_view
      bus["/gtk/window/panes_container"].data = gtk_panes_box
      gtk_edit_view.pack_start(gtk_project)
      gtk_edit_view.pack_start(gtk_panes_box)
      gtk_table.attach(gtk_edit_view,
                   # X direction            # Y direction
                   0, 1,                    2, 3,
                   Gtk::EXPAND | Gtk::FILL, Gtk::EXPAND | Gtk::FILL,
                   0,      0)  
      @gtk_speedbar = Redcar::SpeedbarDisplay.new # is an hbox
      bus["/gtk/window/speedbar"].data = @gtk_speedbar
      gtk_table.attach(@gtk_speedbar,
                   # X direction            # Y direction
                   0, 1,                    3, 4,
                   Gtk::EXPAND | Gtk::FILL, Gtk::FILL,
                   0,      0)  
      gtk_status_hbox = Gtk::HBox.new
      bus["/gtk/window/statusbar"].data = gtk_status_hbox
      gtk_status1 = Gtk::Statusbar.new
      gtk_status2 = Gtk::Statusbar.new  
      bus["/gtk/window/statusbar/status1"].data = gtk_status1
      bus["/gtk/window/statusbar/status2"].data = gtk_status2
      gtk_status_hbox.pack_start(gtk_status1)
      gtk_status_hbox.pack_start(gtk_status2)
      gtk_table.attach(gtk_status_hbox,
                   # X direction            # Y direction
                   0, 1,                    4, 5,
                   Gtk::EXPAND | Gtk::FILL, Gtk::FILL,
                   0,      0)  
      add(gtk_table)
      
      pane = Redcar::Pane.new self
      @notebooks_panes[pane.gtk_notebook] = pane
      gtk_panes_box.add(pane.gtk_notebook)
      
      @initial_show_widgets = 
        [
         gtk_table,
         gtk_status_hbox,
         gtk_status1,
         gtk_status2,
         gtk_panes_box,
         gtk_toolbar,
         gtk_edit_view,
         @gtk_menubar,
         pane.gtk_notebook
        ]
    end
    
    def show_initial_widgets
      @initial_show_widgets.each {|w| w.show }
      show
    end
    
  end
end
