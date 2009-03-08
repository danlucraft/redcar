
module Cucumber
  module Formatter
    class GtkFormatter < Pretty
      
      def visit_step(step)
        Gtk.main_iteration while Gtk.events_pending?
        super
      end
    end
  end
end
