
module Redcar
  class Command
    class Executor
      include Redcar::Core::HasLogger
      
      def self.current_environment
        win = Redcar.app.focussed_window        
        tab = Redcar.app.focussed_notebook_tab
        { :win => win,
          :tab => tab }
      end
      
      def initialize(command_instance, options={})
        @command_instance = command_instance
        @options          = options
      end
      
      def execute
        @command_instance.environment(Executor.current_environment)
        begin
          if not @options.empty?
            result = @command_instance.execute(@options) 
          else
            result = @command_instance.execute
          end
        rescue Object => e
          @command_instance.error = e
          print_command_error(e)
        rescue java.lang.StackOverflowError => e
          @command_instance.error = e
          print_command_error(e)
        end
        record
        result
      end
      
      private

      def print_command_error(e)
        puts "Error in command #{@command_instance.class}"
        puts e.class.to_s + ": " + e.message.to_s
        puts e.backtrace
      end
      
      def record
        if Redcar.app.history
          Redcar.app.history.record(@command_instance)
        end
      end
    end
  end
end
