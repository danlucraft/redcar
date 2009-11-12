module Redcar
  class ApplicationSWT
    class ShellListener
      include org.eclipse.swt.events.ShellListener
      
      def shell_activated event
      end
      
      def shell_closed event
        Redcar.gui.stop
      end
      
      def shell_deactivated event
      end
      
      def shell_deiconified event
      end
      
      def shell_iconified event
      end
    end
  end
end
