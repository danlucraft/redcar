

class Redcar::EditView
  class AutoCompleter
  
    # TODO: maybe this should be based on the grammar of the language
    # that is active in order to make this as flexible as possible...
    WORD_BOUNDARIES = /(\s|\t|\.|\r|\(|\)|,|;)/
    
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
      @buf.signal_connect("mark_set") do |w, iter, mark|
        if mark == @buf.cursor_mark
          @state.cursor_moved
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
      def check_cursor
        puts "check_cursor called"
      end
    end
    
    class InWordState < AutocompleteState
      def cursor_moved
        check_cursor
      end
      
      def character_typed
        
      end
    end
    
    class NotInWordState < AutocompleteState
      def cursor_moved
        check_cursor
      end
      
      def character_typed
        
      end
    end
  end
end
