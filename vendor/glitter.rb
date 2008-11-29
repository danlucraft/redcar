require 'gtk2'

class Gtk::Container
  alias :old_add :add
  
  def add(*args, &blk)
    old_add(*args)
    args.first.instance_eval &blk if blk
  end
end

class Gtk::Box
  alias :old_pack_start :pack_start
  
  def pack_start(*args, &blk)
    old_pack_start(*args)
    args.first.instance_eval &blk if blk
  end
end

class Gtk::TreeStore
  def contents(col)
    s = []
    each do |_, path, iter|
      s << iter[col].to_s
    end
    s.join("\n")
  end

  # If given col and value, finds the first TreeIter with the 
  # matching column. If given a block, passes each iter to the
  # block and returns the iter for which the block returns true.
  def find_iter(col=nil, value=nil, &block)
    each do |_, _, iter|
      if block
        if block.call[iter]
          return iter
        end
      else
        return iter if iter[col] == value
      end
    end
    nil
  end
end

class Gtk::ListStore
  def empty?
    !iter_first
  end
end

class Gtk::TreeIter
  def find_iter(col, value)
    iter = first_child
    return nil unless iter
    return iter if iter[col] == value
    while iter.next!
      return iter if iter[col] == value
    end
    nil
  end
end

class Gtk::TextMark
  def line
    buf = self.buffer
    iter = buf.get_iter_at_mark(self)
    iter.line
  end
  
  def line_offset
    buf = self.buffer
    iter = buf.get_iter_at_mark(self)
    iter.line_offset
  end
  
  def offset
    buf = self.buffer
    iter = buf.get_iter_at_mark(self)
    iter.offset
  end
  
  def to_s
    buf = self.buffer
    iter = buf.get_iter_at_mark(self)
    "<#{iter.line},#{iter.line_offset}>"
  end
end

class Gtk::TextIter
  def forward_cursor_position!
    self.forward_cursor_position
    self
  end
  
  def backward_cursor_position!
    self.backward_cursor_position
    self
  end
  
  def forward_word_end!
      self.forward_word_end
    self
  end
  
  def backward_word_start!
    self.backward_word_start
    self
  end
end
  
class Gtk::Window
  def quit_on_destroy
    signal_connect(:destroy) { Gtk.main_quit }
  end
end

class Gtk::Widget
  def on_key_press(key, &block)
    @__gltr_key_presses ||= {}
    @__gltr_key_presses[key] = block
    return if @__gltr_key_press_handler
    @__gltr_key_press_handler = self.signal_connect("key-press-event") do |_, gdk_eventkey|
      thiskey = Redcar::Keymap.clean_gdk_eventkey(gdk_eventkey)
      if @__gltr_key_presses.include? thiskey
        @__gltr_key_presses[thiskey].call
      end
    end
  end
  
  def on_button_press(&block)
    signal_connect("button-press-event") do |_, gdk_event|
      if gdk_event.is_a? Gdk::EventButton
        block.call(self, gdk_event)
        true
      else
        false
      end
    end
  end
  
  def on_right_button_press(&block)
    signal_connect("button-press-event") do |_, gdk_event|
      if gdk_event.is_a? Gdk::EventButton and gdk_event.button == 3
        block.call(self, gdk_event)
        true
      else
        false
      end
    end
  end
end

class GLib::Instantiatable
  # Attaches debug output handlers to every signal
  # that this object has.
  # This does not include the "notify" signal, which is
  # emitted so often that it overwhelms the output.
  def debug_signals
    self.class.signals.each do |v|
      unless v == "notify"
        self.signal_connect(v) do |args|
          puts "#{v} occurred with args #{args.inspect}"
        end
      end
    end
  end
end
