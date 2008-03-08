
module Redcar
  class Pane
    extend FreeBASE::StandardPlugin
    
    attr_accessor :gtk_notebook, :window
    attr_reader   :label_angle,  :label_position
    
    def initialize(window)
      @window = window
      make_notebook
      connect_notebook_signals
      show_notebook
    end
    
    def new_tab(type=EditTab, *args)
      tab = type.new(self, *args)
      add_tab(tab)
      tab
    end
    
    def close_tab(tab)
      @window.close_tab(tab)
    end
    
    def close_all_tabs
      tabs.each{|tab| @window.close_tab(tab)}
    end
    
    def tabs
      (0...@gtk_notebook.n_pages).map do |i|
        Tab.widget_to_tab[@gtk_notebook.get_nth_page(i)]
      end
    end

    def active_tab
      Tab.widget_to_tab[@gtk_notebook.get_nth_page(@gtk_notebook.page)]
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
      @gtk_notebook.signal_connect("button_press_event") do |gtk_widget, gtk_event|
        gtk_widget.grab_focus
        if gtk_event.kind_of? Gdk::EventButton and gtk_event.button == 3
          bus('/redcar/services/context_menu_popup').call("Pane", gtk_event.button, gtk_event.time)
        end
      end
      @gtk_notebook.signal_connect("page-added") do |nb, gtk_widget, _, _|
        tab = Tab.widget_to_tab[gtk_widget]
        tab.label_angle = @label_angle
        tab.pane = self
        false
      end
      @gtk_notebook.signal_connect("switch-page") do |nb, _, page_num|
        @window.update_focussed_tab(Tab.widget_to_tab[nb.get_nth_page(page_num)])
        puts "switch_page: #{nb.inspect}, #{page_num}"
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
