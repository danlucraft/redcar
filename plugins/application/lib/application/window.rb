
module Redcar
  class Application
    class Window
      include Redcar::Model
      
      attr_reader :menu
      
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
      
      def menu=(menu)
        @menu = menu
        controller.menu_changed
      end
    end
  end
end
