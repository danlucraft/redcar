
module Redcar
  class Menu
    attr_reader :text
    
    # A Menu will initially have nothing in it.
    def initialize(text="")
      @text, @entries = text, []
    end
    
    # Add a Redcar::MenuItem or a Redcar::Menu
    def <<(entry)
      @entries << entry
      self
    end
    
    # Number of entries in the menu
    def length
      @entries.length
    end
  end
end
