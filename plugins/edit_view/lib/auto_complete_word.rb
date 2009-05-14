

class Redcar::EditView
  class AutoCompleter
  
    # TODO: maybe this should be based on the grammar of the language
    # that is active in order to make this as flexible as possible...
    WORD_BOUNDARIES = /\w/ # /(\s|\t|\.|\r|\(|\)|,|;)/
    
    def initialize(buffer)
      @buf = buffer
      @parser = buffer.parser
      buffer.autocompleter = self
      @state = NotInWordState.new(self)
      connect_signals
    end
    
    def connect_signals
      #connect_insert_text_signal
      #connect_delete_range_signal
      @buf.signal_connect("mark_set") do |document, iter, mark|
        if mark == @buf.cursor_mark
          @state.cursor_moved(document, iter, mark)
          puts @state
        end
      end
    end
    
    def connect_insert_text_signal
      @buf.signal_connect("insert_text") do |document,iter,text,length|
        
      end
    end
        
    def connect_delete_range_signal
      @buf.signal_connect("delete_range") do |document, iter1, iter2|
        
      end
    end
    
    def multiple_characters_typed(text)
      
    end
        
    def complete_word
      puts "complete word in AutoCompleteWord called! yay."
      @word_before_cursor = @buf.word_before_cursor
    end
    
    def state=(state)
      @state = state
    end
    
    # class for Autocomplete state machine
    class AutocompleteState
      @last_cursor_line = -1
      
      # returns the word (see WORD_BOUNDARIES) that the cursor is currently touching.
      # nil otherwise.
      def word_touching_cursor(document)
        unless document.cursor_line == @last_cursor_line
          @line = document.get_line
          @last_cursor_line = document.cursor_line
        end
        left, right = word_range(document)
        document.get_slice(document.iter(left), document.iter(right))
      end
      
      # returns the range that holds the current word (depending on WORD_BOUNDARIES)
      def word_range(document)
        left = document.cursor_line_offset - 1
        right = document.cursor_line_offset
        left_range = 0
        right_range = 0
        offset = document.cursor_offset
        
        until left == -1 || WORD_BOUNDARIES !~ (@line[left].chr)
          left -= 1
          left_range -= 1
        end
        
        until right == @line.length || WORD_BOUNDARIES !~ (@line[right].chr)
          right += 1
          right_range += 1
        end
        return [offset+left_range, offset+right_range]
      end
      
      def state=(state)
        @state = state
      end
      
      def initialize(autocompleter)
        @autocompleter = autocompleter
      end
    end
    
    class InWordState < AutocompleteState
      def cursor_moved(document, iter, mark)
        touched_word = word_touching_cursor(document) 
        if touched_word.length == 0
          @autocompleter.state = NotInWordState.new(@autocompleter)
        end
      end
      
      def character_typed
        
      end
    end
    
    class NotInWordState < AutocompleteState
      def cursor_moved(document, iter, mark)
        touched_word = word_touching_cursor(document)
        unless touched_word.length == 0
          @autocompleter.state = InWordState.new(@autocompleter)
        end
      end
      
      def character_typed
        
      end
    end
  end
end
