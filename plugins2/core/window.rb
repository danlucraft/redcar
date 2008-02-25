
require 'gtk2'

module Redcar
  class Window < Gtk::Window
    extend FreeBASE::StandardPlugin
    
    def self.start(plugin)
      App.new_window
      plugin.transition(FreeBASE::RUNNING)
    end
    
    def self.stop(plugin)
      App.close_all_windows
      plugin.transition(FreeBASE::LOADED)
    end
    
    def initialize
      super("Redcar")
      @notebooks_panes = {}
      build_widgets
      connect_signals
      show_initial_widgets
    end
    
    def close
      # TODO: uncomment next line
      # panes.each {|pane| pane.close.each {|tab| tab.close} }
      Keymap.clear_keymaps_from_object(self)
      App.close_window(self, true)
    end
    
    def panes
      @notebooks_panes.values
    end
    
    def unify_all
    end
    
    def new_tab(tab_class, focus = true)
      
    end
    
    def tabs
      panes.map {|pane| pane.tabs }.flatten
    end
    
    def active_tabs
    end
    
    def focussed_tab
    end
    
    def focus_previous_tab
    end
    
    def focus_tab(name)
    end

    def split_horizontal(pane)
      split_pane(:horizontal, pane)
    end
    
    def split_vertical(pane)
      split_pane(:vertical, pane)
    end
    
    def unify(pane)
      panes_container = pane.gtk_notebook.parent
      unless panes_container.class = Gtk::OneBox
        other_side = panes_container.children.find do |p|
          p != pane.gtk_notebook
        end
        panes_container.remove(pane.gtk_notebook)
        panes_container.remove(other_side)
        if [Gtk::HPaned, Gtk::VPaned].include? other_side.class
          other_tabs = collect_tabs_from_dual(other_side)
        else
          other_tabs = other_side.tabs
        end
        container_of_container = panes_container.parent
        other_panes = tabs.map{|t| t.pane}.uniq
        tabs.each do |tab|
          tab.pane.move_tab(tab, pane)
        end
        other_panes.each{|op| op.close}
        if container_of_container.child1 == panes_container
          container_of_container.remove panes_container
          container_of_container.add1 pane.gtk_notebook
        else
          container_of_container.remove panes_container
          container_of_container.add2 pane.gtk_notebook
        end
      end
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
      panes_container = bus("/gtk/window/panes_container").data
      if panes_container.child == pane.gtk_notebook
        panes_container.remove(pane.gtk_notebook)
        dual.add(new_pane.gtk_notebook)
        dual.add(pane.gtk_notebook)
        panes_container.add(dual)
      else
        panes_container = pane.gtk_notebook.parent
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
      signal_connect('key-press-event') do |gtk_widget, gdk_eventkey|
        continue = Keymap.process(gdk_eventkey)
        # falls through to Gtk widget if nothing handles it
        continue
      end
    end
    
    def build_widgets
      set_size_request(800, 600)
      gtk_menubar = Gtk::MenuBar.new 
      gtk_table = Gtk::Table.new(1, 4, false)
      bus["/gtk/window/table"].data = gtk_table
      bus["/gtk/window/menubar"].data = gtk_menubar
      gtk_table.attach(gtk_menubar,
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
      gtk_panes_box = Gtk::OneBox.new
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
                   0, 1,                    3, 4,
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
         gtk_menubar
        ]
    end
    
    def show_initial_widgets
      @initial_show_widgets.each {|w| w.show }
      show
    end
  end
end
