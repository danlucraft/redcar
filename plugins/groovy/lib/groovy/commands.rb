
module Redcar
  class Groovy
    class GroovyOpenREPL < Redcar::REPL::OpenREPL
      def execute
        open_repl(ReplMirror.new)
      end
    end
  end
end