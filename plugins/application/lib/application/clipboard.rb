module Redcar
  # Models a copy/paste clipboard that can contain multiple elements.
  #
  # Each entry in the Clipboard is an array of Strings, like these:
  #
  #      ["mytext"]
  #      ["foo", "bar"]
  #
  # Each entry is an array of Strings in order to support copy/paste in 
  # block selection mode.
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
    
    # Add an entry to the clipboard.
    #
    # Events: [:added, Array<String>]
    #
    # @param [String, Array<String>]
    def <<(text)
      if text.is_a?(String)
        text = [text]
      end
      return if text == [""]
      
      @contents << text
      if @contents.length == Clipboard.max_length + 1
        @contents.delete_at(0)
      end
      notify_listeners(:added_internal, text)
      notify_listeners(:added, text)
    end
    
    # The most recent entry added to the Clipboard
    #
    # @return [Array<String>]
    def last
      check_for_changes
      @contents.last
    end
    
    # The number of entries on the Clipboard
    def length
      check_for_changes
      @contents.length
    end
    
    # Fetch an entry. 0 is the most recent
    #
    # @return [Array<String>]
    def [](index)
      check_for_changes
      @contents[-1*index-1]
    end
    
    # Iterate over each entry.
    def each(&block)
      check_for_changes
      @contents.each(&block)
    end
    
    # Add an entry without raising an event.
    #
    # @param [String, Array<String>]
    def silently_add(text)
      @contents << text
    end
    
    private
    
    def check_for_changes
      if controller and controller.changed?
        if @contents.length > 0
          controller.last_set = @contents.last.join("\n")
        end
        contents = controller.get_contents
        self << contents if contents
      end
    end
  end
end


