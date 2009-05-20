
class Redcar::EditView
  class AutoCompleter
  
    # this method and the rest of this file define the state machine context
    # for the cursor movement tracked by the current autocomplete implementation.
    def define_cursor_state_machine
      state_machine = Statemachine.build do
        trans :in_word_state, :cursor_moved, :check_word_state # start state, event, target state -> check for touching word
        trans :not_in_word_state, :cursor_moved, :check_word_state
        state :check_word_state do
          on_entry :check_for_word
          event :not_in_word, :not_in_word_state
          event :in_word, :in_word_state
        end
      end
      
      state_machine.context = AutocompleteCursorStateContext.new(@buf)
      state_machine.context.statemachine = state_machine
      @cursor_state = state_machine
    end

    class AutocompleteCursorStateContext
      attr_accessor :statemachine
      
      def initialize(doc)
        @document = doc
      end
      
      # returns the word that is being touched by the cursor and an array containing [left, right] document offsets of the word.
      def touched_word
        @line = @document.get_line
        left, right = word_range
        word = @document.get_slice(@document.iter(left), @document.iter(right))
        return nil if word.length == 0
        return word, [left, right]
      end
      
      private
      def check_for_word
        @touched_word, _ = touched_word
        if @touched_word
          @statemachine.in_word
        else
          @statemachine.not_in_word
        end
      end
      
      # returns the range that holds the current word (depending on WORD_CHARACTERS)
      def word_range
        left = @document.cursor_line_offset - 1
        right = @document.cursor_line_offset
        left_range = 0
        right_range = 0
        offset = @document.cursor_offset
        
        until left == -1 || WORD_CHARACTERS !~ (@line[left].chr)
          left -= 1
          left_range -= 1
        end
        
        until right == @line.length || WORD_CHARACTERS !~ (@line[right].chr)
          right += 1
          right_range += 1
        end
        return [offset+left_range, offset+right_range]
      end
    end
  end
end
