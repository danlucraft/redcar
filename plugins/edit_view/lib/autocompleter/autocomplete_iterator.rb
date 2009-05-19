class AutocompleteIterator
  def initialize(buffer, word_chars)
    @buf = buffer
    @word_chars = word_chars
  end

  # word_chars is a regex, that defined word characters
  # we cannot use GTK::TextIter right now since starts_word? and others are not adequate for programming languages.
  def each_word_with_offset
    inside_word = false
    iter = @buf.iter(@buf.start_mark)
    end_iter = @buf.end_iter
    word_offset = 0
    word = []
    
    until iter == end_iter
      char = iter.char
      if char =~ @word_chars
        unless inside_word
          word_offset = iter.offset
          inside_word = true
        end
        word << char
      else
        if inside_word
          yield word.join, word_offset
          inside_word = false
          word = []
        end
      end
      iter.set_offset(iter.offset+1)
    end
    
    # also yield the last word of the document
    unless word.length == 0
      yield word.join, word_offset
    end
  end
end
