
module Redcar
  class ApplicationSWT
    class Window
      include Redcar::Controller
      
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
    end
  end
end
