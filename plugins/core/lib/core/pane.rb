
module Redcar
  # A Pane is a container for Tabs. A Redcar window may
  # have multiple Panes. Panes can be split
  # horizontally and vertically to allow the user to lay out their
  # workspace as they see fit. Tabs can be dragged from one Pane to
  # another.
  #
  # Plugin authors should not create Panes by hand, rather they should
  # use Pane#split_horizontal and Window#panes to create and locate
  # panes.
  class Pane
    extend FreeBASE::StandardPlugin
    include FreeBASE::DataBusHelper

    # The Pane's Gtk::Notebook.
    attr_accessor :gtk_notebook
    # The Window the Pane is in.
    attr_accessor :window
    # The label_angle of the tabs in the Pane.
    attr_reader   :label_angle
    # The label_position of the tabs in the Pane.
    attr_reader   :label_position

    # Do not call this directly. Creates a new pane
    # attached to the given window. Redcar::Window manages
    # the creation of panes.
    def initialize(window)
      @window = window
      make_notebook
      connect_notebook_signals
      show_notebook
    end

    # Creates a new Tab in the Pane. tab_type should be
    # Redcar::Tab or child class. args are passed
    # on to tab_type#initialize.
    def new_tab(tab_type=EditTab, *args)
      if tab_type.singleton? and existing_instance = tab_type.instance
        return existing_instance
      end
      tab = tab_type.new(self, *args)
      add_tab(tab)
      Hook.trigger :new_tab, tab
      tab
    end

    # Return an array of all Tabs in this Pane.
    def tabs
      (0...@gtk_notebook.n_pages).map do |i|
        Tab.widget_to_tab[@gtk_notebook.get_nth_page(i)]
      end
    end

    # Return the active Tab in this Pane. Note that this may
    # not be the currently focussed Tab in the Window.
    def active_tab
      Tab.widget_to_tab[@gtk_notebook.get_nth_page(@gtk_notebook.page)]
    end

    # Return all Tabs in this Pane with class tab_class.
    def collect_all(tab_class)
    end

    # Replace this Pane in the Window with two new Panes, on
    # the left and right.
    def split_vertical
      @window.split_vertical(self)
    end

    # Replace this Pane in the Window with two new Panes, on
    # the top and bottom.
    def split_horizontal
      @window.split_horizontal(self)
    end

    # Undo the split_horizontal or split_vertical that created
    # this tab.
    def unify
      @window.unify(self)
    end

    # Move Tab tab to Pane dest_pane.
    def move_tab(tab, dest_pane)
      remove_tab(tab)
      dest_pane.add_tab(tab)
    end

    def add_tab(tab) #:nodoc:
      tab.label_angle = @label_angle
      @gtk_notebook.append_page(tab.gtk_nb_widget, tab.label)
      @gtk_notebook.set_tab_reorderable(tab.gtk_nb_widget, true)
      @gtk_notebook.set_tab_detachable(tab.gtk_nb_widget, true)
      @gtk_notebook.show_all
      @gtk_notebook.set_menu_label(tab.gtk_nb_widget, tab.menu_label)
      tab.pane = self
    end

    def focus_tab(tab) #:nodoc:
      if tab.pane == self
        @gtk_notebook.set_page(@gtk_notebook.page_num(tab.gtk_nb_widget))
        tab.gtk_nb_widget.grab_focus
      else
        raise "focussing tab in wrong pane"
      end
    end

    private

    def make_notebook
      @gtk_notebook = Gtk::Notebook.new
      @gtk_notebook.set_group_id 0
      @gtk_notebook.homogeneous = false
      @gtk_notebook.scrollable = true
      @gtk_notebook.enable_popup = true
    end

    def connect_notebook_signals
      # @gtk_notebook.signal_connect("button_press_event") do |gtk_widget, gtk_event|
      #   gtk_widget.grab_focus
      #   if gtk_event.kind_of? Gdk::EventButton and gtk_event.button == 3
      #     bus('/redcar/services/context_menu_popup').call("Pane", gtk_event.button, gtk_event.time)
      #   end
      # end
      @gtk_notebook.signal_connect("page-added") do |nb, gtk_widget, _, _|
        tab = Tab.widget_to_tab[gtk_widget]
        tab.label_angle = @label_angle
        tab.pane = self
        false
      end
      @gtk_notebook.signal_connect("switch-page") do |nb, _, page_num|
        @window.update_focussed_tab(Tab.widget_to_tab[nb.get_nth_page(page_num)])
#        puts "switch_page: #{nb.inspect}, #{page_num}"
        true
      end
    end

    def show_notebook
      @gtk_notebook.show
    end

    def remove_tab(tab)
      @gtk_notebook.remove(tab.gtk_nb_widget)
      tab.pane = nil
    end

    def label_angle=(angle)
      @label_angle = angle
      tabs.each do |tab|
        tab.label_angle = angle
      end
    end

    def label_position=(position)
      @label_position = position
      case position
      when :bottom
        @gtk_notebook.set_tab_pos(Gtk::POS_BOTTOM)
      when :left
        @gtk_notebook.set_tab_pos(Gtk::POS_LEFT)
      when :right
        @gtk_notebook.set_tab_pos(Gtk::POS_RIGHT)
      else
        @gtk_notebook.set_tab_pos(Gtk::POS_TOP)
      end
    end
  end
end
