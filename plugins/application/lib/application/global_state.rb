module Redcar
  class Application
    class GlobalState
      def app
        Redcar.app
      end
      
      def win
        app and app.focussed_window
      end
      
      def project
        win and Project.in_window(win)
      end

      def tab
        win and win.focussed_notebook_tab
      end
    end
  end
end