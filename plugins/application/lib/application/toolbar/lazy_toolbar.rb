
module Redcar
  class Toolbar
    class LazyToolbar < Toolbar
      
      def initialize(block, text=nil, options={})
        @text = text
        @block = block
        @priority = options[:priority] || Toolbar::DEFAULT_PRIORITY
      end
      
      def entries
        Toolbar::Builder.build(&@block).entries
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
