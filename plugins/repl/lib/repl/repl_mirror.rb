module Redcar
  class REPL
    class ReplMirror
      attr_reader :history, :command_history, :current_command, :current_offset

      # A ReplMirror is a type of Document::Mirror
      include Redcar::Document::Mirror

      def initialize
        @history = initial_preamble
        @mutex = Mutex.new
        initialize_command_history
      end

      def initialize_command_history
        @command_history = REPL.storage['command_history'][title] || []
        @command_history_buffer_size = REPL.storage['command_history_buffer_size']
        @current_command = @command_history.size
        set_current_offset
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

      # The tab title and preamble to display
      # Default: "REPL"
      #
      # @return [String]
      def title
        "REPL"
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
          last = contents.split(prompt).last
          if last
            last.strip
          else
            ""
          end
        end
      end

      def command_history_buffer_size
        @command_history_buffer_size
      end

      def command_history_buffer_size=(size)
        @command_history_buffer_size = size
      end

      # The previous command to the command currently displayed,
      # or the last one executed, if none.
      def previous_command
        command = @command_history.last
        current = @current_command
        if current
          if @command_history.size > 0 and current > 0
            @current_command = current - 1
            command = @command_history[@current_command]
          end
        end
        command
      end

      # The next command to the command currently displayed,
      # or blank, if none.
      def next_command
        command = ""
          if @current_command and @command_history.size > @current_command + 1
            @current_command = @current_command + 1
            command = @command_history[@current_command]
          end
        command
      end

      def add_command(expr)
        @command_history.push expr
        size = @command_history.size
        buffer_size = @command_history_buffer_size
        @command_history.shift(size - buffer_size) if size > buffer_size
        @current_command = @command_history.size
      end

      def set_current_offset
        @current_offset = @history.split(//).length
      end

      # Evaluate an expression. Calls execute on the return value of evaluator
      def evaluate(expr)
        add_command(expr)
        if expr == 'clear'
          clear_history
        else
          @history += expr + "\n"
          begin
            @history += "=> " + evaluator.execute(expr)
          rescue Object => e
            @history += "x> " + format_error(e)
          end
          @history += "\n" + prompt + " "
          set_current_offset
          notify_listeners(:change)
        end
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