
class Redcar::EditView
  # When you type ", ', ( or [ with a selection, Wrapper will
  # make it not typeover the selection, and instead put the corresponding
  # pair at the front and back of the selection.
  class Wrapper
    WRAP_PAIRS = {
      '"' => '"',
      "[" => "]",
      "(" => ")",
      "{" => "}"
    }
    def initialize(view)
      @view = view
      connect_signals
    end
    
    def connect_signals
      @view.signal_connect("key-press-event") do |_, gdk_eventkey|
        p [:keypress_event, Redcar::Keymap.clean_gdk_eventkey(gdk_eventkey)]
        if WRAP_PAIRS.include?Redcar::Keymap.clean_gdk_eventkey(gdk_eventkey) and 
            @view.buffer.selection?
          p :wrapper_should_do_something_here
          
          true
        else
          false
        end
      end
    end
  end
end
    
