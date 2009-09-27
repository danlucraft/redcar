
module Redcar
  class Menu
    attr_reader :text
    
    # A Menu will initially have no items.
    def initialize(text="")
      @text, @items = text, []
    end
    
    # Add a Redcar::MenuItem
    def <<(item)
      @items << item
    end
    
    # Number of items in the menu
    def length
      @items.length
    end
  end
end
