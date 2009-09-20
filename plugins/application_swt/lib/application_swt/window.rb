
module Redcar
  module ApplicationSWT
    class Window
      def initialize(window)
        @window = window
        @shell = Swt::Widgets::Shell.new(ApplicationSWT.display)
        @shell.open
        @shell.text = window.title
      end

      def close
        @shell.close
      end
    end
  end
end
