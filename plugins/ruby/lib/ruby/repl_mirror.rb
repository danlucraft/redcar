
module Redcar
  class Ruby
    class REPLMirror < Redcar::REPL::REPLMirror

      def title
        "Ruby REPL"
      end

      def grammar_name
        "Ruby REPL"
      end

      def prompt
        ">>"
      end

      def format_error(e)
        backtrace = e.backtrace.reject{|l| l =~ /repl_mirror/}
        backtrace.unshift("(repl):1")
        "#{e.class}: #{e.message}\n        #{backtrace.join("\n        ")}"
      end

      def evaluator
        @evaluator ||= REPLMirror::Evaluator.new
      end

      class Evaluator
        attr_reader :output

        def initialize
          @binding = binding
          @output = nil
        end

        def inspect
          "main"
        end

        def execute(command)
          eval(command, @binding).inspect
        end
      end
    end
  end
end
