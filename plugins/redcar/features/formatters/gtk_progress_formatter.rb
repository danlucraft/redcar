
module Cucumber
  module Formatter
    class GtkProgressFormatter < Progress
      def visit_step(step)
        @finished_step = false
        Gtk.queue do
          super(*args)
          @finished_step = true
        end
        loop do
          sleep 0.1
          break if @finished_step and not Gdk::Event.events_pending?
        end
        if time_str = ENV['GUTKUMBER_SLEEP']
          sleep time_str.to_f
        end
      end
    end
  end
end
