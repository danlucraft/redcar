
module Cucumber
  module Formatter
    class GtkFormatter < Pretty
      def visit_step(*args)
        @finished_step = false
        Gtk.queue do
          super(*args)
          @finished_step = true
        end
        loop do
          sleep 0.1
          break if @finished_step
        end
        if time_str = ENV['GUTKUMBER_SLEEP']
          sleep time_str.to_f
        end
      end
    end
  end
end
