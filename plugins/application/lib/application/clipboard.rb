module Redcar
  # A simple array with a maximum length. Models a copy/paste clipboard
  # that can contain multiple elements.
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
    
    # Add text to the clipboard.
    #
    # @param [String, Array<String>]
    def <<(text)
      if text.is_a?(String)
        text = [text]
      end
      @contents << text
      if @contents.length == Clipboard.max_length + 1
        @contents.delete_at(0)
      end
      notify_listeners(:added_internal, text)
      notify_listeners(:added, text)
    end
    
    def last
      check_for_changes
      @contents.last
    end
    
    def length
      check_for_changes
      @contents.length
    end
    
    def [](index)
      check_for_changes
      @contents[-1*index-1]
    end
    
    def each(&block)
      check_for_changes
      @contents.each(&block)
    end
    
    def silently_add(text)
      @contents << text
    end
    
    private
    
    def check_for_changes
      if controller and controller.changed?
        controller.last_set = @contents.last.join("\n")
        self << controller.get_contents
      end
    end
  end
end


