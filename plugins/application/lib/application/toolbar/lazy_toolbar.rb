
module Redcar
  class ToolBar
    class LazyToolBar < ToolBar
      
      def initialize(block, text=nil, options={})
        @text = text
        @block = block
        @priority = options[:priority] || ToolBar::DEFAULT_PRIORITY
      end
      
      def entries
        ToolBar::Builder.build(&@block).entries
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
