
# the list of words plus their relative distance (beginning of the word to the cursor)
# this information can just be updated, as long as the cursor is moving through the document.
# as soon as typing happens, a word will have to be added or replaced.
class WordList
  include Enumerable
  
  attr_reader :words
  
  def initialize()
    @words = []
    @offset = 0
  end
  
  def cursor_offset=(offset)
    @words.each do |word|
      difference = @offset - offset
      word.distance += difference
    end
    
    @offset = offset
  end
  
  def cursor_offset
    @offset
  end
  
  # adds a new word, iff it doesn't yet exist.
  # if the word exists, the distance will be adjusted, if it's lower.
  def add_word(word, distance)
    @words << Word.new(word, distance)
  end
  
  def each
    @words.each { |word| yield word }
  end
  
  class Word
    attr_accessor :word, :distance
    def initialize(word, distance)
      @word, @distance = word, distance
    end
    
    def to_s
      @word.to_s.ljust(30) + @distance.to_s
    end
  end
end
