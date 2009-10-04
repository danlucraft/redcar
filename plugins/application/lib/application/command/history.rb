
module Redcar
  # A module holding the Redcar command history. The maximum length
  # defaults to 500.
  class Command
    class History
      def initialize
        @commands   = []
        @max       = 500
      end
    
      # Add a command to the command history if CommandHistory.recording is
      # true.
      def record(command)
        if command.record?
          @commands << command
        end
        prune
      end
    
      # Adds a command to the command history if CommandHistory.recording is
      # true. If the last command is of the same class, it is replaced.
      def record_and_replace(command)
        if command.record?
          if last.class == command.class
            @commands[-1] = command
          else
            @commands << command
          end
        end
        prune
      end
    
      # Clear the command history.
      def clear
        @commands = []
      end
      
      # Number of commands in the history
      def length
        @commands.length
      end
      
      # Set the maximum length of the history
      def max=(max)
        @max = max
      end
      
      # The last command recorded
      def last
        @commands.last
      end
        
      
      private
      
      def prune #:nodoc:
        (@commands.length - @max).times { @commands.delete_at(0) }
      end
    end
  end
end




