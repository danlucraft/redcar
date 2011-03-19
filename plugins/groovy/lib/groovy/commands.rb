
module Redcar
  class Groovy
    class OpenGroovyREPL < Redcar::REPL::OpenREPL
      def execute
        open_repl(ReplMirror.new)
      end
    end
  end
end