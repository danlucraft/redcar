module Redcar
  class REPL
    class ReplMirror
      attr_reader :history
      
      # A ReplMirror is a type of Document::Mirror
      include Redcar::Document::Mirror

      def initialize
        @history = initial_preamble
        @mutex = Mutex.new
      end
      
      # What to display when the REPL is opened. Defaults to the title followed
      # by a prompt
      #
      # @return [String]
      def initial_preamble
        "# #{title}\n\n#{prompt} "
      end
      
      # The name of the textmate grammar to apply to the repl history.
      #
      # @return [String]
      def grammar_name
        raise "implement the grammar_name method on your REPL"
      end
      
      # The prompt to display when the REPL is ready to accept input.
      # Default: ">>"
      #
      # @return [String]
      def prompt
        ">>"
      end
      
      # This returns an object that implements:
      #   execute(str:String): String
      def evaluator
        raise "implement evaluator on your REPL"
      end
      
      # Format the language specific exception to be displayed in the Repl
      # 
      # @param [Exception] 
      # @return [String]
      def format_error(exception)
        raise "implement format_error on your REPL"
      end
      
      # Execute a new statement. Accepts the entire pretty formatted history,
      # within which it looks for the last statement and executes it.
      #
      # Do not override
      #
      # @param [String] a string with at least one prompt and statement in it
      def commit(contents)
        command = entered_expression(contents)
        evaluate(command)
      end
      
      # What did the user just enter?
      #
      # @return [String]
      def entered_expression(contents)
        if contents.split("\n").last =~ /#{prompt}\s+$/
          ""
        else
          contents.split(prompt).last.strip
        end
      end

      # Evaluate an expression. Calls execute on the return value of evaluator
      def evaluate(expr)
        @history += expr + "\n"
        begin
          @history += "=> " + evaluator.execute(expr)
        rescue Object => e
          @history += "x> " + format_error(e)
        end
        @history += "\n" + prompt + " "
        notify_listeners(:change)
      end

      # Get the complete history as a pretty formatted string.
      #
      # @return [String]
      def read
        @history
      end
      
      def clear_history
        @history = @history.split("\n").last
        notify_listeners(:change)
      end

      # REPLs always exist because there is no external resource to represent.
      # Therefore, this returns true.
      def exists?
        true
      end

      # REPLs never change except for after commit operations.
      def changed?
        false
      end
    end
  end
end