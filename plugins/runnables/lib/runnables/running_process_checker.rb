module Redcar
  class Runnables
    class RunningProcessChecker
      def initialize(tabs, message, options)
        @tabs, @message, @options = tabs, message, options
      end
      
      def check
        tabs_with_running_processes = @tabs.select {|t| t.html_view.controller and t.html_view.controller.ask_before_closing }
        if tabs_with_running_processes.any?
          result = Application::Dialog.message_box(
            "You have #{tabs_with_running_processes.length} running processes.\n\n" + 
            @message,
            :buttons => :yes_no_cancel
          )
          case result
          when :yes
            tabs_with_running_processes.each do |t|
              t.focus
              t.close
            end
            @options[:continue] ? @options[:continue].call : nil
          when :no
            @options[:continue] ? @options[:continue].call : nil
          when :cancel
            @options[:cancel] ? @options[:cancel].call : nil
          end
        else
          @options[:none] ? @options[:none].call : nil
        end
      end
    end
  end
end