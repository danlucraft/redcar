
module Redcar
  class Application
    class Window
      include Redcar::Model
      
      # All instantiated windows
      def self.all
        @all ||= []
      end

      def initialize
        Window.all << self
      end

      def show
        controller.show
      end

      def title
        "Redcar"
      end
      
      attr_reader :menu

      def menu=(menu)
        controller.menu_changed(menu)
      end
    end
  end
end
