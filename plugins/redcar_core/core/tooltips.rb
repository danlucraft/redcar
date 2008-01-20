

module Redcar
  class ToolTip < Gtk::Window
    @@visible_tooltips = []
    
    def self.hide_all
      @@visible_tooltips.each {|tt| tt.hide}
      @@visible_tooltips = []
    end
    
    def initialize(x=50, y=50, text="[blank tooltip]")
      ToolTip.hide_all
      super(Gtk::Window::POPUP)
      set_border_width(1)
      label = Gtk::Label.new(text)
      add(label)
      move(x, y)
      Redcar.hook :keystroke do 
        ToolTip.hide_all
        false
      end
      show_all
      @@visible_tooltips << self
      @@tooltip_handlers ||= []
      @@tooltip_handlers << Redcar.current_tab.textview.signal_connect("button_press_event") do 
        clear_tooltips
      end
      Thread.new do 
        sleep 3
        clear_tooltips
      end
    end
    
    def clear_tooltips
      @@visible_tooltips.each {|tt| tt.hide }
      @@visible_tooltips.clear
      @@tooltip_handlers.each do |th|
        if Redcar.current_tab.textview.signal_handler_is_connected?(th)
          Redcar.current_tab.textview.signal_handler_disconnect(th)
        end
      end
    end
  end
  
  class TextTab
    
    def tooltip_at_cursor(label)
      rect = @textview.get_iter_location(iter(cursor_mark))
      x1, y1 = @textview.buffer_to_window_coords(Gtk::TextView::WINDOW_WIDGET, rect.x, rect.y)
      x2, y2  = @textview.get_window(Gtk::TextView::WINDOW_WIDGET).origin
      ToolTip.new(x1+x2, y1+y2+20, label)
    end
  end
end
