module Redcar
  class Command
    class Executor
      def self.current_environment
        {:win => Redcar.app.windows.first}
      end
      
      def initialize(command_instance, options={})
        @command_instance = command_instance
        @options          = options
      end
      
      def execute
        @command_instance.environment(Executor.current_environment)
        @command_instance.execute
        record
      end
      
      private
      
      def record
        if Redcar.history
          Redcar.history.record(@command_instance)
        end
      end
    end
  end
end
