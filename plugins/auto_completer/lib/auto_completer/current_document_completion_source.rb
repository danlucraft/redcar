module Redcar
  class AutoCompleter
    class CurrentDocumentCompletionSource
      def initialize(document, _)
        @document = document
      end
      
      def alternatives(prefix)
        iterator = WordIterator.new(@document, WORD_CHARACTERS)
        word_list = WordList.new
        iterator.each_word_with_offset(prefix) do |matching_word, offset|
          distance = (offset - @document.cursor_offset).abs
          word_list.add_word(matching_word, distance)
        end
        word_list
      end
    end
  end
end