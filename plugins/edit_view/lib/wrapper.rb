
class Redcar::EditView
  # When you type ", ', ( or [ with a selection, Wrapper will
  # make it not typeover the selection, and instead put the corresponding
  # pair at the front and back of the selection.
  class Wrapper
    WRAP_PAIRS = {
      '"' => '"',
      "[" => "]",
      "(" => ")",
      "{" => "}",
      "<" => ">"
    }
    def initialize(view)
      @view = view
      connect_signals
    end
    
    def buffer
      @view.buffer
    end
    
    def connect_signals
      @view.signal_connect("key-press-event") do |_, gdk_eventkey|
        char = Redcar::Keymap.clean_gdk_eventkey(gdk_eventkey)
        if WRAP_PAIRS.include? char and 
            buffer.selection?
          left, right = *[buffer.cursor_mark, buffer.selection_mark].sort_by do |mark|
            buffer.iter(mark).offset
          end
          buffer.insert(buffer.iter(left), char)
          buffer.insert(buffer.iter(right), WRAP_PAIRS[char])
          buffer.select(right_iter = buffer.iter(right), right_iter)
          true
        else
          false
        end
      end
    end
  end
end
    
