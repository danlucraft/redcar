

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
      
      @typing_word = false
      @word = []
    end
    
    def connect_signals
      connect_insert_text_signal
      connect_delete_range_signal
    end
    
    def connect_insert_text_signal
      @buf.signal_connect("insert_text") do |document,iter,text,length|
        if length == 1
          single_character_typed(text)
        else
          multiple_characters_typed(text)
        end
      end
    end
    
    def connect_delete_range_signal
      @buf.signal_connect("delete_range") do |document, iter1, iter2|
        length = iter2.offset - iter1.offset
        if length == 1
          single_character_deleted
        else
          multiple_characters_deleted
        end
      end
    end
    
    # updates this AutoCompleters buffer that
    # keeps track of the words in this document.
    def single_character_typed(text)
      unless text =~ WORD_BOUNDARIES
        @word.push(text)
        unless @typing_word
          @typing_word = true
        end
      else
        unless @word.size == 0
          word_completed
        end
      end
    end
    
    def single_character_deleted
      if @typing_word
        @word.pop
        if @word.size == 0
          @typing_word = false
        end
      end
    end
    
    def multiple_characters_typed(text)
      # this happens with tabs for example
      if @typing_word
        word_completed
      else
        rebuild_from_document
      end
    end
    
    def multiple_characters_deleted
      # TODO: this should not happen if only whitespace was deleted.
      rebuild_from_document
    end
    
    def rebuild_from_document
      
    end
        
    def complete_word
      puts "complete word in AutoCompleteWord called! yay."
      @word_before_cursor = @buf.word_before_cursor
    end
    
    
    private
    # method that gets called once a complete word has been typed.
    def word_completed
      word = @word.join
      @word = []
      @typing_word = false
      puts "typed word #{word}"
    end
  end
end
