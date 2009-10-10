module Redcar
  class Command
    class Executor
      def initialize(command_instance, opts={})
        @command_instance = command_instance
        @opts = opts
      end
      
      def execute
        @command_instance.execute
      end
    end
  end
end
