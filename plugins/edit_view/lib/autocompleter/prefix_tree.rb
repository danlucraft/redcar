class PrefixTree
  attr_reader :number_of_words
  
  def initialize()
    @root_node = PrefixTreeNode.new
    @number_of_words = 0
  end
  
  def <<(word)
    @root_node.add(word, 0)
    @number_of_words += 1
    self
  end
  
  def all_with_prefix(prefix)
    current = @root_node
    prefix.each_char do |c|
      if current.children[c]
        current = current.children[c] 
      else # there are no words with this prefix
        return []
      end
    end
    
    result = []
    current.depth_first_visit do |word|
      result << word
    end
    return result
  end
  
  def to_s
    result = ""
    @root_node.depth_first_visit do |word|
      result << word << "\n"
    end
    return result
  end
  
  
  class PrefixTreeNode
    attr_reader :word, :children
  
    def initialize
      @children = Hash.new # TODO: may be replaced with array, if alphabet size is know
    end
    
    def add(word, prefix_length)
      unless word.length == prefix_length
        character = word[prefix_length].chr
        
        if @children.include?(character)
          @children[character].add(word, prefix_length + 1)
        else
          new_node = PrefixTreeNode.new
          @children[character] = new_node
          new_node.add(word, prefix_length + 1)
        end
      
      else
        @word = word
      end
    end
    
    def depth_first_visit(&block)
      if @word
        yield @word
      end
      
      @children.keys.sort.each do |key|
        @children[key].depth_first_visit(&block)
      end
    end
  end
end
