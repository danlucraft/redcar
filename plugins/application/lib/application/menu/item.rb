
module Redcar
  class Menu
    class Item
      class Separator < Item
        def initialize
          super(nil, nil)
        end
      end
      
      attr_reader :text, :command
  
      # Create a new Item, with the given text to display in the menu, and
      # either:
      #   the Redcar::Command that is run when the item is selected.
      #   or a block to run when the item is selected
      def initialize(text, command=nil, &block)
        @text, @command = text, command
        if !command & block
          @command = block
        end
      end
      
      # Call this to signal that the menu item has been selected by the user.
      def selected
        @command.new.run
      end
      
      def merge(other)
        @command = other.command
      end
      
      def ==(other)
        text == other.text and command == other.command
      end
    end
  end
end