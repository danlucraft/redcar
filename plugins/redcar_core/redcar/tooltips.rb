

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
      modify_bg(Gtk::STATE_NORMAL, Gdk::Color.parse("#FFFFCC"))
      label = Gtk::Label.new(text)
      add(label)
      move(x, y)
      Redcar.hook :keystroke do 
        ToolTip.hide_all
        false
      end
      show_all
      @@visible_tooltips << self
      Thread.new do 
        sleep 3
        self.hide
        @@visible_tooltips.delete(self)
      end
    end
  end
  
  class TextTab
    #keymap "ctrl b", :tooltip_at_cursor, "foo"
    
    def tooltip_at_cursor(label)
      rect = @textview.get_iter_location(iter(cursor_mark))
      x1, y1 = @textview.buffer_to_window_coords(Gtk::TextView::WINDOW_WIDGET, rect.x, rect.y)
      x2, y2  = @textview.get_window(Gtk::TextView::WINDOW_WIDGET).origin
      ToolTip.new(x1+x2, y1+y2+20, label)
    end
  end
end
