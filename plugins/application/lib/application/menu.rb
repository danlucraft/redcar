
module Redcar
  class Menu
    include Enumerable
    include Redcar::Model
    
    attr_reader :text, :entries
  
    # A Menu will initially have nothing in it.
    def initialize(text=nil)
      @text, @entries = text || "", []
    end
  
    # Iterate over each entry
    def each
      entries.each {|e| yield e}
    end
  
    # Add a Redcar::MenuItem or a Redcar::Menu
    def <<(entry)
      entries << entry
      self
    end
  
    # Number of entries in the menu
    def length
      entries.length
    end
    
    # Fetch the sub_menu with the given name
    #
    # @param [String]
    # @return [Menu]
    def sub_menu(text)
      detect {|e| e.text == text and e.is_a?(Menu) }
    end
    
    def entry(text)
      detect {|e| e.text == text }
    end
    
    # Append items and sub_menus using the same syntax as Menu::Builder
    def build(&block)
      Menu::Builder.new(self, &block)
    end
    
    def ==(other)
      return false unless length == other.length
      return false unless text == other.text
      entries.zip(other.entries) do |here, there|
        return false unless here.class == there.class and here == there
      end
      true
    end
    
    # Merge two Menu trees together. Modifies this Menu.
    #
    # @param [Menu] another Menu
    def merge(other)
      other.entries.each do |other_entry|
        if here = entry(other_entry.text)
          if here.class == other_entry.class
            here.merge(other_entry)
          else
            entries[entries.index(here)] = other_entry
          end
        else
          self << other_entry
        end
      end
    end
  end
end
