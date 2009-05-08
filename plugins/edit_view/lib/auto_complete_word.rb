
class Redcar::EditView
  class AutoCompleteWord
    
    
    def initialize(buffer)
      @buffer = buffer
      @parser = buffer.parser
      buffer.autocompleter = self
    end
    
    
    def complete_word
      puts "complete word in AutoCompleteWord called! yay."
    end
  end
end
