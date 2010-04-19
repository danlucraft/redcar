
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
          result = @command_instance.execute
        rescue Object => e
          @command_instance.error = e
        rescue java.lang.StackOverflowError => e
          @command_instance.error = e
        end
        record
        result
      end
      
      private
      
      def record
        if Redcar.app.history
          Redcar.app.history.record(@command_instance)
        end
      end
    end
  end
end
