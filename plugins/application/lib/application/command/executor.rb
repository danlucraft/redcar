module Redcar
  class Command
    class Executor
      def initialize(command_instance, opts={})
        @command_instance = command_instance
        @opts = opts
      end
      
      def execute
      end
    end
  end
end
