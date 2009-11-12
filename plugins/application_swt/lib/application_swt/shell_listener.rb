module Redcar
  class ApplicationSWT
    class ShellListener
      include org.eclipse.swt.events.ShellListener
      
      def shell_activated(event) # Shell is active window
      end
      
      def shell_closed(event)
        Redcar.gui.stop
      end
      
      def shell_deactivated(event) # Shell is no longer active window
      end
      
      def shell_deiconified(event) # Minimize Shell
      end
      
      def shell_iconified(event) # Maximize Shell
      end
    end
  end
end
