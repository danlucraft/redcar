class AutocompleteIterator
  def initialize(buffer, word_chars)
    @buf = buffer
    @word_chars = word_chars
  end

  # Iterates through each character in the document. For each one the character and the document offset is returned
  def each_char
    iter = iter(start_mark)
    until iter == end_iter
      yield iter.char, iter.offset
      iter.offset += 1
    end
  end

  # iterates through each wordm defined as by PANGO rules, yields word + offset
  # word_cahrs is a regex, that defined word characters
  # we cannot use GTK::TextIter right now since starts_word? and others are not adequate for programming languages.
  def each_word_with_offset
    inside_word = false
    iter = @buf.iter(@buf.start_mark)
    word_offset = 0
    word = []
    
    until iter == @buf.end_iter
    
      if iter.char =~ @word_chars
        unless inside_word
          word_offset = iter.offset-1
          inside_word = true
        end
        word << iter.char
      else
        if inside_word
          yield word.join, word_offset
          inside_word = false
          word = []
        end
      end
      iter.offset += 1
    end
    
  end
end
