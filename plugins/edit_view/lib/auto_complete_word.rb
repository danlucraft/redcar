

class Redcar::EditView
  class AutoCompleter
    
    WORD_BOUNDARIES = /(\s|\t|\.|\r)/
    
    def initialize(buffer)
      @buf = buffer
      @parser = buffer.parser
      buffer.autocompleter = self
      connect_signals
      
      @typing_word = false
      @word = []
    end
    
    def connect_signals
      @buf.signal_connect("insert_text") do |document,iter,text,length|
        case length
        when 1
          single_character_typed(text)
        else
          multiple_characters_typed(text)
        end
      end
    end
    
    # updates this AutoCompleters buffer that
    # keeps track of the words in this document.
    def single_character_typed(text)
      unless text =~ WORD_BOUNDARIES
        @word << text
        unless @typing_word
          @typing_word = true
        end
      else
        unless @word.size == 0
          word = @word.join
          @word = []
          @typing_word = false
          puts "typed word #{word}"
        end
      end
    end
    
    def multiple_characters_typed(text)
      
    end
    
    def complete_word
      puts "complete word in AutoCompleteWord called! yay."
      @word_before_cursor = @buf.word_before_cursor
    end
  end
end
