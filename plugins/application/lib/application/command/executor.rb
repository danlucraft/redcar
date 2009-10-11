module Redcar
  class Command
    class Executor
      def initialize(command_instance, options={})
        @command_instance = command_instance
        @options          = options
      end
      
      def execute
        @command_instance.execute
        if Redcar.history
          Redcar.history.record(@command_instance)
        end
      end
    end
  end
end
