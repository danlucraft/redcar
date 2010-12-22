
module Redcar
  class Terminal
    class ReplMirror < Redcar::REPL::ReplMirror
      def title
        "Terminal"
      end

      def help
        <<-HELP
I am a Terminal REPL. I accept shell commands.
Someday I hope to grow up to be a real Terminal,
but for now I am only a "proof of concept".
Use the 'clear' command to erase command output,
or the 'reset' command to clear all command history.
HELP
      end

      def grammar_name
        "Shell Script (Bash)"
      end

      def prompt
        "$"
      end

      def evaluator
        @evaluator ||= Evaluator.new
      end

      def format_error(e)
        "ERROR #{e.class}:\n #{e.message}\n"
      end

      class Evaluator
        attr_reader :output

        def initialize
          @output = nil
        end

        def inspect
          "terminalREPL main"
        end

        def execute(cmd)
          stdin,out,err = IO.popen3(cmd)
          output = out.read
          errors = err.read
          output = "" unless output
          if errors and not errors.strip.empty?
            errors
          else
            output
          end
        end
      end
    end
  end
end