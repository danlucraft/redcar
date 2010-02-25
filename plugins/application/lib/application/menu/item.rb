
module Redcar
  class Menu
    class Item
      class Separator < Item
        def initialize
          super(nil, nil)
        end
      end
      
      attr_reader :text, :command, :block
  
      # Create a new Item, with the given text to display in the menu, and
      # either:
      #   the Redcar::Command that is run when the item is selected.
      #   or a block to run when the item is selected
      def initialize(text, command=nil, &block)
        @text, @command = text, command
        if !command & block
          @command = block
        # if command and block are set, set the block attribute
        elsif command && block
          @block = block
        end
      end
      
      # Call this to signal that the menu item has been selected by the user.
      # This runs the Item's Command
      def selected
        if @block
          c = @command.new
          # block is called, passing the returned variable into the Command's block attribute
          # This was implemented for RecentDirectories plugin
          # Refactor if you feel necessary
          c.block(@block.call)
          c.run
        else
          @command.new.run
        end
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