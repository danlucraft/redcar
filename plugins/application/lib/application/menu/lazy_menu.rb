
module Redcar
  class Menu
    class LazyMenu < Menu
      
      def initialize(block, text=nil)
        @text = text
        @block = block
      end
      
      def entries
        Menu::Builder.build(&@block).entries
      end
      
      def <<(*_)
        raise
      end
      
      def merge(*_)
        raise
      end
    end
  end
end
