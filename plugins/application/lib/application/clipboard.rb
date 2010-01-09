module Redcar
  # A simple array with a maximum length. Models a clipboard for 
  # copying and pasting.
  class Clipboard
    include Redcar::Model
    include Redcar::Observable
    include Enumerable
    
    def self.max_length
      10
    end

    attr_reader :name
  
    def initialize(name)
      @name     = name
      @contents = []
    end
    
    def <<(text)
      @contents << text
      if @contents.length == Clipboard.max_length + 1
        @contents.delete_at(0)
      end
      notify_listeners(:added, text)
    end
    
    def last
      @contents.last
    end
    
    def length
      @contents.length
    end
    
    def [](index)
      @contents[-1*index-1]
    end
    
    def each(&block)
      @contents.each(&block)
    end
  end
end