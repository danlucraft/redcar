module Redcar
  class Grammar
    module Ruby
      
      def word_chars
        /(\w|_)+("?"|"!")?/
      end
    end
  end
end
