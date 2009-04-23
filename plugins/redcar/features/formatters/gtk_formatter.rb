
module Cucumber
  module Formatter
    class GtkFormatter < Pretty
      def visit_step(step)
        while Gtk.events_pending?
          Gtk.main_iteration 
        end
        super
        if time_str = ENV['GUTKUMBER_SLEEP']
          sleep time_str.to_f
        end
      end
    end
  end
end
