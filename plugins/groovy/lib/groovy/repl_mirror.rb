
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
          output = @shell.evaluate(cmd).to_s
          output = "null" unless output and not output.strip.empty?
          if @out and not @out.toString().strip.empty?
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
