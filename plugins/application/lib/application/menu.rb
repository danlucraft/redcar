
module Redcar
  class Menu
    # A Menu will initially have no items.
    def initialize
      @items = []
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
