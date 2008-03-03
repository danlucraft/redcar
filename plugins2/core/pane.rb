
module Redcar
  class Pane
    extend FreeBASE::StandardPlugin
    
    attr_accessor :gtk_notebook
    attr_reader   :label_angle,  :label_position
    
    def initialize(window)
      @window = window
      make_notebook
      connect_notebook_signals
      show_notebook
    end
    
    def new_tab(type=TextTab, *args)
      tab = type.new(self, *args)
      add_tab(tab)
      tab
    end
    
    def close_tab(tab)
      tab.close
    end
    
    def close_all_tabs
      tabs.each{|tab| tab.close}
    end
    
    def tabs
      (0...@gtk_notebook.n_pages).map do |i|
        Tab.widget_to_tab[@gtk_notebook.get_nth_page(i)]
      end
    end

    def active_tab
      Tab.widget_to_tab[@gtk_notebook.get_nth_page(@gtk_notebook.page)]
    end

    def focus_tab(tab)
      id = @gtk_notebook.page_num(tab.gtk_nb_widget)
      @gtk_notebook.set_page(id)
    end
    
    def collect_all(tab_class)
    end
    
    def split_horizontal
      @window.split_horizontal(self)
    end
    
    def split_vertical
      @window.split_vertical(self)
    end
    
    def unify
      @window.unify(self)
    end
    
    def move_tab(tab, dest_pane)
      remove_tab(tab)
      dest_pane.add_tab(tab)
    end

    def add_tab(tab)
      tab.label_angle = @label_angle
      @gtk_notebook.append_page(tab.gtk_nb_widget, tab.label)
      @gtk_notebook.set_tab_reorderable(tab.gtk_nb_widget, true)
      @gtk_notebook.set_tab_detachable(tab.gtk_nb_widget, true)
      @gtk_notebook.show_all
      tab.pane = self
    end
    
    private

    def make_notebook
      @gtk_notebook = Gtk::Notebook.new
      @gtk_notebook.set_group_id 0
    end
    
    def connect_notebook_signals
      @gtk_notebook.signal_connect("button_press_event") do |widget, event|
        if event.kind_of? Gdk::EventButton 
          if event.button == 3
            bus['/redcar/services/context_menu_popup'].call("Pane", event.button, event.time)
          end
        end
      end
      @gtk_notebook.signal_connect("page-added") do |nb, widget, _, _|
        tab = Tab.widget_to_tab[widget]
        tab.label_angle = @label_angle
        tab.pane = self
        false
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
