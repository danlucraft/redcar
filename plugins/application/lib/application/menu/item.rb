
module Redcar
  class Menu
    class Item
      class Separator < Item
        def initialize
          super(nil, nil)
        end
      end
      
      attr_reader :text, :command
  
      def initialize(text, command)
        @text, @command = text, command
      end
    end
  end
end