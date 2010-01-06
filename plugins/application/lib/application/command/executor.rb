
module Redcar
  class Command
    class Executor
      include Redcar::Core::HasLogger
      
      def self.current_environment
        win = Redcar.app.focussed_window
        tab = Redcar.app.focussed_window.focussed_notebook.focussed_tab
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
          result = @command_instance.execute
        rescue Object => e
          @command_instance.error = e
          log_error
        rescue java.lang.StackOverflowError => e
          @command_instance.error = e
          log_error
        end
        record
        result
      end
      
      private
      
      def log_error
        logger.error "* Error in command #{@command_instance.class}"
        if @command_instance.error.respond_to?(:backtrace)
          logger.error "  " + @command_instance.error.message.to_s
          @command_instance.error.backtrace.each {|l| logger.error("  " + l) }
        end
      end
      
      def record
        if Redcar.history
          Redcar.history.record(@command_instance)
        end
      end
    end
  end
end
