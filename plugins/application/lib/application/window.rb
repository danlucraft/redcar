
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

      def show
        controller.show
      end

      def title
        "Redcar"
      end
    end
  end
end
