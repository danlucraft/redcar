
module Redcar
  class ApplicationSWT
    class Window
      include Redcar::Controller
      
      attr_reader :shell
      
      def initialize
        @shell = Swt::Widgets::Shell.new(ApplicationSWT.display)
      end
        
      def show
        @shell.open
        @shell.text = @model.title
      end

      def close
        @shell.close
      end
      
      def menu_changed(menu)
        @menu_controller = ApplicationSWT::Menu.new(self, menu)
        shell.menu_bar = @menu_controller.menu_bar
      end
    end
  end
end
