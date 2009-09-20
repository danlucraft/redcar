
module Redcar
  module ApplicationSWT
    class Window
      def initialize
        @shell = Swt::Widgets::Shell.new(ApplicationSWT.display)
        @shell.open
      end
    end
  end
end
