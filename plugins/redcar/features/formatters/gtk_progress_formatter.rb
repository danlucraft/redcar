
module Cucumber
  module Formatter
    class GtkProgressFormatter < Progress
      
      def visit_step(step)
        super
        while Gtk.events_pending?
          Gtk.main_iteration
        end
      end
    end
  end
end
