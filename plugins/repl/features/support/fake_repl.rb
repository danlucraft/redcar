
module Redcar
  class REPL
    class FakeEvaluator
      def execute(expr)
        "#{expr} was entered"
      end
    end

    class OpenFakeREPL < OpenREPL
      def execute
        open_repl(REPLMirror.new)
      end
    end
  end
end