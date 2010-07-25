
module Redcar
  class Menu
    class Item
      class Separator < Item
        def initialize
          super(nil, nil)
        end
        
        def is_unique?
          true
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
      def selected(with_key=false)
        @command.new.run#(:with_key => with_key)
      end
      
      def merge(other)
        @command = other.command
      end
      
      def ==(other)
        text == other.text and command == other.command
      end
      
      def is_unique?
        false
      end
    end
  end
end