
require 'java'

module Redcar
  class Groovy
    class ReplMirror < Redcar::REPL::ReplMirror
      def title
        "Groovy REPL"
      end

      def grammar_name
        "Groovy REPL"
      end

      def prompt
        "groovy>"
      end

      def evaluator
        @instance ||= ReplMirror::Evaluator.new
      end

      def format_error(e)
        backtrace = e.backtrace
        "ERROR #{e.class}:\n #{e.message}\n        #{backtrace.join("\n        ")}"
      end

      def help
        h = super
        h << """
Note on Groovy Script Scoping:
Classes, undefined variables, and undefined closures are saved in the script
binding between statements.
Defined methods, closures, and variables are not added to the binding,
because they are considered local variables and thus are not available after
the defining statement.

Example:

def foo = 'hello! I am a local variable'
foo = 'hi! I am a binding variable'

See 'http://groovy.codehaus.org/Scoping+and+the+Semantics+of+%22def%22'
for more information.
"""
      end

      class Evaluator
        def self.load_dependencies
          unless @loaded
            Groovy.load_dependencies
            import 'groovy.lang.GroovyShell'
            import 'java.io.PrintWriter'
            import 'java.io.StringWriter'
            @loaded = true
          end
        end

        def initialize
          Evaluator.load_dependencies
          @out = StringWriter.new
          @shell = GroovyShell.new
          @shell.setProperty('out',@out)
        end

        def inspect
          "groovyREPL main"
        end

        def execute(cmd)
          output = @shell.evaluate(cmd,"GroovyREPL").to_s
          output = "null" unless output and not output.empty?
          if @out and not @out.toString().empty?
            console = @out.toString() + "\n"
          else
            console = ""
          end
          buf = @out.getBuffer()
          buf.delete(0,buf.length()) if buf.length() > 0
          console + "===> #{output}"
        end
      end
    end
  end
end