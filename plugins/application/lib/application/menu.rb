
module Redcar
  class Menu
    include Enumerable
    
    attr_reader :text, :entries
  
    # A Menu will initially have nothing in it.
    def initialize(text=nil)
      @text, @entries = text || "", []
    end
  
    # Iterate over each entry
    def each
      @entries.each {|e| yield e}
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
    
    # Fetch the sub_menu with the given name
    #
    # @param [String]
    # @return [Menu]
    def sub_menu(text)
      detect {|e| e.text == text and e.is_a?(Menu) }
    end
    
    # Append items and sub_menus using the same syntax as Menu::Builder
    def build(&block)
      Menu::Builder.new(self, &block)
    end
  end
end