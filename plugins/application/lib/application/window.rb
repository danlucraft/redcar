
module Redcar
  class Application
    class Window
      # All instantiated windows
      def self.all
        @all ||= []
      end
        
      def initialize
        Window.all << self
      end
      
      def title
        "Redcar"
      end
    end
  end
end
