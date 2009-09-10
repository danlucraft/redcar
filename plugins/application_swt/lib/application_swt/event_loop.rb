
module Redcar
  class ApplicationSWT
    class EventLoop
      def initialize
        @running = false
      end
      
      # Begins the SWT event loop. Blocks.
      def start
        @running = true
        while @running
          unless ApplicationSWT.display.read_and_dispatch
            ApplicationSWT.display.sleep
          end
        end
        ApplicationSWT.display.dispose
      end
      
      # Halts the SWT event loop.
      def stop
        @running = false
      end
    end
  end
end
