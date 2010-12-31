
module Redcar
  class Mirah
    class ReplMirror < Redcar::REPL::ReplMirror

      def title
        "Mirah REPL"
      end

      def grammar_name
        "Ruby REPL"
      end

      def prompt
        ">>"
      end

      def format_error(e)
        backtrace = e.backtrace.reject{|l| 
          l =~ /(repl_mirror|redcar)/
        }
        backtrace.unshift("(repl):1")
        "#{e.class}: #{e.message}\n        #{backtrace.join("\n        ")}"
      end

      def evaluator
        @evaluator ||= ReplMirror::Evaluator.new
      end

      class Evaluator
        attr_reader :output

        def initialize
          Mirah.load_dependencies
          @binding = binding
          @impl   = Java::MirahImpl::Mirah.new
          @output = nil
        end

        def inspect
          "main"
        end

        def execute(command)
          @impl.instance_eval(command).inspect
        end
      end
    end
  end
end