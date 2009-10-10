
module Redcar
  class Menu
    class Item
      class Separator < Item
        def initialize
          super(nil, nil)
        end
      end
      
      attr_reader :text, :command
  
      # Create a new Item, with the given text to display in the menu, and the
      # Redcar::Command that is run when the item is selected.
      def initialize(text, command)
        @text, @command = text, command
      end
      
      # Call this to signal that the menu item has been selected by the user.
      # This runs the Item's Command
      def selected
        @command.new.run
      end
    end
  end
end