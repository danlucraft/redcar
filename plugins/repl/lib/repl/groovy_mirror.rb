
require 'java'

module Redcar
  class REPL
    class GroovyMirror
      def self.load_groovy_dependencies
        unless @loaded
          require File.join(Redcar.asset_dir,"groovy-all")
          import 'groovy.lang.GroovyShell'
          import 'java.io.PrintWriter'
          import 'java.io.StringWriter'
          @loaded = true
        end
      end
      include Redcar::REPL::ReplMirror

      def initialize
        GroovyMirror.load_groovy_dependencies
        @prompt = "groovy>"
        @history = "// Groovy REPL\n\n#{@prompt} "
        @instance = Main.new
      end

      def title
        "Groovy REPL"
      end

      def grammar_name
        "Groovy REPL"
      end

      def read
        @history
      end

      def clear_history
        @history = @history.split("\n").last
        notify_listeners(:change)
      end

      class Main
        def initialize
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

      def format_error(e)
        backtrace = e.backtrace
        "ERROR #{e.class}:\n #{e.message}\n        #{backtrace.join("\n        ")}"
      end

      def send_to_repl expr
        @history += expr + "\n"
        begin
          @history += @instance.execute(expr)
        rescue Object => e
          @history += format_error(e)
        end
        @history += "\n" + @prompt + " "
        notify_listeners(:change)
      end
    end
  end
end
