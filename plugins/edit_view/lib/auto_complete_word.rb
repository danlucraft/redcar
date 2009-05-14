

class Redcar::EditView
  class AutoCompleter
  
    # TODO: maybe this should be based on the grammar of the language
    # that is active in order to make this as flexible as possible...
    WORD_BOUNDARIES = /\w/ # /(\s|\t|\.|\r|\(|\)|,|;)/
    
    def initialize(buffer)
      @buf = buffer
      @parser = buffer.parser
      buffer.autocompleter = self
      connect_signals
      
      @state = NotInWordState.new
    end
    
    def connect_signals
      #connect_insert_text_signal
      #connect_delete_range_signal
      @buf.signal_connect("mark_set") do |document, iter, mark|
        if mark == @buf.cursor_mark
          @state.cursor_moved(document, iter, mark)
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
    
    # class for Autocomplete state machine
    class AutocompleteState
      @last_cursor_line = -1
      
      # determines whether the cursor is currently in a word and
      # returns the current word if so,
      # nil otherwise.
      def cursor_in_word(document, iter, mark)
        unless document.cursor_line == @last_cursor_line
          @line = document.get_line
          @last_cursor_line = document.cursor_line
        end
        range = word_range(document)
        nil
      end
      
      # returns the range that holds the current word (depending on WORD_BOUNDARIES)
      def word_range(document)
        left = document.cursor_line_offset - 1
        right = document.cursor_line_offset
        left_range = 0
        right_range = 0
        
        until left == -1 || WORD_BOUNDARIES !~ (@line[left].chr)
          left -= 1
          left_range -= 1
        end
        
        until WORD_BOUNDARIES !~ (@line[right].chr) || right == (@line.length)
          right += 1
          right_range += 1
        end
        
        offset = document.cursor_offset
        word = document.get_slice(document.iter(offset+left_range), document.iter(offset+right_range))
        puts "current word: #{word}"
      end
    end
    
    class InWordState < AutocompleteState
      def cursor_moved(document, iter, mark)
        unless cursor_in_word(document, iter, mark)
          @state = NotInWordState.new
          puts @state
        end
      end
      
      def character_typed
        
      end
    end
    
    class NotInWordState < AutocompleteState
      def cursor_moved(document, iter, mark)
        if cursor_in_word(document, iter, mark)
          @state = InWordState.new
          puts @state
        end
      end
      
      def character_typed
        
      end
    end
  end
end
