
# the list of words plus their relative distance (beginning of the word to the cursor)
# this information can just be updated, as long as the cursor is moving through the document.
# as soon as typing happens, a word will have to be added or replaced.
class WordList
  include Enumerable
  
  attr_reader :words
  
  def initialize()
    @words = Hash.new
    @offset = 0
  end
  
  def cursor_offset=(offset)
    # TODO: enable incremental updating of cursor offset
    @offset = offset
  end
  
  def cursor_offset
    @offset
  end
  
  # adds a new word, iff it doesn't yet exist.
  # if the word exists, the distance will be adjusted, if it's lower.
  def add_word(word, distance)
    if @words.include?(word)
      if distance < @words[word]
        @words[word] = distance
      end
    else
      @words[word] = distance
    end
  end
  
  # yield the completions for the given prefix
  def completions(prefix)
    r = /^#{prefix}/
    filtered = @words.keys.select{ |word| word =~ r }
    return filtered.sort!{|a,b| @words[a] <=> @words[b] }
  end
  
  def each
    @words.each {|word,distance| yield word, distance }
  end
end
