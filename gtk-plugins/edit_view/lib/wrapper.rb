
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
    
    def self.load_possible_characters
      @possible_characters = []
      Redcar::Bundle.bundles.each do |bundle|
        bundle.preferences.each do |key, value|
          if smart_pairs = (value['settings']||{})['smartTypingPairs']
            smart_pairs.each do |smart_pair|
              @possible_characters << smart_pair.first
            end
          end
        end
      end
      @possible_characters.uniq!
    end
    
    def self.possible_characters
      load_possible_characters unless @possible_characters
      @possible_characters
    end
    
    private

    # Accepts a Gtk::TextView
    def initialize(view)
      @view = view
      connect_signals
    end
    
    def buffer
      @view.buffer
    end
    
    def right_character(scope, lchar)
      setting = Redcar::Bundle.best_preference(scope, 'smartTypingPairs')
      if pair = setting.detect{|a| a.first == lchar}
        pair.last
      end
    end
    
    def connect_signals
      @view.signal_connect("key-press-event") do |_, gdk_eventkey|
        lchar = Redcar::Keymap.clean_gdk_eventkey(gdk_eventkey)
        if Wrapper.possible_characters.include? lchar and 
            buffer.selection?
          if rchar = right_character(buffer.cursor_scope, lchar)
            left, right = *[buffer.cursor_mark, buffer.selection_mark].sort_by do |mark|
              buffer.iter(mark).offset
            end
            buffer.insert(buffer.iter(left), lchar)
            buffer.insert(buffer.iter(right), rchar)
            buffer.select(right_iter = buffer.iter(right), right_iter)
            true
          end
        else
          false
        end
      end
    end
  end
end
    
