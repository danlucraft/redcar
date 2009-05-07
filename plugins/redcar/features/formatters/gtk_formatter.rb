
module Cucumber
  module Formatter
    class GtkFormatter < Pretty
      # def mod(event)
      #   if event.is_a?(Gdk::EventKey)
      #     Redcar::Keymap.clean_gdk_eventkey(event)
      #   else
      #     event
      #   end
      # end
      
      def visit_step(*args)
        Gtk.main_iteration while Gtk.events_pending?
        Gtk.execute_pending_blocks
        super
        if time_str = ENV['GUTKUMBER_SLEEP']
          sleep time_str.to_f
        end
        # @finished_step = false
        # Gtk.queue do
        #   super(*args)
        #   @finished_step = true
        # end
        # current_event = nil
        # mod_current_event = nil
        # time_started = nil
        # loop do
        #   sleep 0.2
        #   if mod(Gtk.current_event) != current_event
        #     time_started = Time.now
        #     current_event = mod(Gtk.current_event)
        #   end
        #   
        #   break if @finished_step and 
        #     not Gdk::Event.peek and
        #     (current_event.nil? or (Time.now - time_started > 1))
        # end
        # if time_str = ENV['GUTKUMBER_SLEEP']
        #   sleep time_str.to_f
        # end
      end
    end
  end
end
