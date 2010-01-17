
module Redcar
  class AutoCompleter
    class WordIterator
      def initialize(document, word_chars)
        @document = document
        @word_chars = word_chars
      end
    
      # word_chars is a regex, that defines word characters
      def each_word_with_offset(prefix)
        inside_word = false
        text = @document.to_s
        char_offset = 0
        word_offset = 0
        word = []

        text.each_char do |char|
          if char =~ @word_chars
            unless inside_word
              word_offset = char_offset
              inside_word = true
            end
            word << char
          else
            if inside_word
              joined = word.join
              if joined =~ /^#{prefix}/
                yield joined, word_offset
              end
              inside_word = false
              word = []
            end
          end
          char_offset += 1
        end
        
        # also yield the last word of the document (why???)
        if word.join =~ /^#{prefix}/
          yield word.join, word_offset
        end
      end
    end
  end
end