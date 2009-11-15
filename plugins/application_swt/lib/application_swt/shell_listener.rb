module Redcar
  class ApplicationSWT
    class ShellListener
      include org.eclipse.swt.events.ShellListener
      
      def add_close_event &block
        @on_close ||= []
        @on_close << block
      end
      
      def shell_activated(event) # Shell is active window
      end
      
      def shell_closed(event)
        @on_close.each do |event|
          event.call
        end
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
