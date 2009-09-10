
module Redcar
  class ApplicationSWT
    class EventLoop
      def initialize
        @running = false
      end
      
      # Begins the SWT event loop. Blocks.
      def start
        @running = true
        display = ApplicationSWT.display
        while @running and not display.disposed?
          unless display.read_and_dispatch
            display.sleep
          end
        end
        display.dispose
      end
      
      # Halts the SWT event loop.
      def stop
        @running = false
      end
    end
  end
end
