
module Cucumber
  module Formatter
    class GtkFormatter < Pretty
      
      def visit_step(step)
        super
        Gtk.main_iteration while Gtk.events_pending?
      end
    end
  end
end
