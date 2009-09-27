
module Redcar
  class Application
    class Window
      include Redcar::Model
      
      # All instantiated windows
      def self.all
        @all ||= []
      end

      attr_reader :notebook

      def initialize
        Window.all << self
        @notebook = Redcar::Notebook.new
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
