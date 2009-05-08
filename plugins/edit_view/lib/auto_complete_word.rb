
class Redcar::EditView
  class AutoCompleteWord
    
    def initialize(buffer)
      @buf = buffer
      @parser = buffer.parser
      buffer.autocompleter = self
    end
    
    
    def complete_word
      puts "complete word in AutoCompleteWord called! yay."
      
      @word = @buf.word_before_cursor
      
      puts @word if @word
    end
  end
end
