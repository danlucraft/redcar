
module Cucumber
  module Formatter
    class GtkProgressFormatter < Progress
      
      def visit_step(*args)
        Gtk.main_iteration while Gtk.events_pending?
        Gtk.execute_pending_blocks
        super
        if time_str = ENV['GUTKUMBER_SLEEP']
          sleep time_str.to_f
        end
      end
    end
  end
end
