class AutocompleteIterator
  def initialize(buffer, word_chars)
    @buf = buffer
    @word_chars = word_chars
  end

  # word_chars is a regex, that defined word characters
  # we cannot use GTK::TextIter right now since starts_word? and others are not adequate for programming languages.
  def each_word_with_offset(prefix)
    inside_word = false
    text = @buf.text
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
    
    # also yield the last word of the document
    unless word.length == 0
      yield word.join, word_offset
    end
  end
end
