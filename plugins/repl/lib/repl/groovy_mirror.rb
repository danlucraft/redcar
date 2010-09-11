
require 'java'

module Redcar
  class REPL
    class GroovyMirror
      def self.load_groovy_dependencies
        unless @loaded
          require File.dirname(__FILE__) + "/../../vendor/groovy"
          import 'groovy.lang.GroovyShell'
          @loaded = true
        end
      end
      include Redcar::REPL::ReplMirror

      def initialize
        GroovyMirror.load_groovy_dependencies
        @prompt = "groovy:>"
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
          @shell = GroovyShell.new
        end

        def inspect
          "groovy main"
        end

        def execute(cmd)
          @shell.evaluate(cmd).to_s
        end
      end

      def format_error(e)
        backtrace = e.backtrace
        "ERROR: #{e.class}: #{e.message}\n        #{backtrace.join("\n        ")}"
      end

      def send_to_repl expr
        @history += expr + "\n"
        begin
          @history += "===> " + @instance.execute(expr)
        rescue Object => e
          @history += format_error(e)
        end
        @history += "\n" + @prompt + " "
        notify_listeners(:change)
      end
    end
  end
end