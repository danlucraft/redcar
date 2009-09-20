
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
    end
  end
end
