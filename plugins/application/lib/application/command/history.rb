
module Redcar
  class Command
    # A class that holds a Redcar command history. The maximum length
    # defaults to 500.
    class History < Array
      def initialize
        @max       = 500
      end
    
      # Add a command to the command history if CommandHistory.recording is
      # true.
      def record(command)
        if command.class.record?
          self << command
        end
        prune
      end
    
      # Adds a command to the command history if CommandHistory.recording is
      # true. If the last command is of the same class, it is replaced.
      def record_and_replace(command)
        if command.class.record?
          if last.class == command.class
            self[-1] = command
          else
            self << command
          end
        end
        prune
      end
    
      # Set the maximum length of the history
      def max=(max)
        @max = max
      end
      
      private
      
      def prune #:nodoc:
        (length - @max).times { delete_at(0) }
      end
    end
  end
end




