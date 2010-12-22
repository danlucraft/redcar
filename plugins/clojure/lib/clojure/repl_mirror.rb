
module Redcar
  class Clojure
    class ReplMirror < Redcar::REPL::ReplMirror

      def title
        "Clojure REPL"
      end

      def grammar_name
        "Clojure REPL"
      end

      def prompt
        "user=>"
      end

      def evaluator
        @evaluator ||= Evaluator.new(self)
      end

      def format_error(e)
        "ERROR: #{e.message}\n\n#{e.backtrace.join("\n")}"
      end

      class Evaluator
        attr_reader :wrapper

        def self.load_dependencies
          unless @loaded
            Clojure.load_dependencies
            import 'redcar.repl.Wrapper'
            @loaded = true
          end
        end

        def initialize(mirror)
          Evaluator.load_dependencies
          @mirror = mirror
          @wrapper ||= begin
            wrapper = Wrapper.new

            @thread = Thread.new do
              loop do
                output = wrapper.getResult
                output =~ /^(.*)\nuser=> /
                @result = $1
              end
            end

            wrapper
          end
        end

        def execute(expr)
          wrapper.sendToRepl(expr)
          true until @result
          str = @result
          @result = nil
          str
        end
      end
    end
  end
end
