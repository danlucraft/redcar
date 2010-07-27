
module Redcar
  class Menu
    class LazyMenu < Menu
      
      def initialize(block, text=nil, options={})
        @text = text
        @block = block
        @priority = options[:priority] || Menu::DEFAULT_PRIORITY
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
