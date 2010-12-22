
module Redcar
  class REPL
    class ShellMirror < ReplMirror
      def title
        "Console"
      end

      def grammar_name
        "Shell Script (Bash)"
      end

      def prompt
        "$"
      end

      def evaluator
        @evaluator ||= ShellMirror::Evaluator.new
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
          "shellREPL main"
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