
require 'java'

module Redcar
  class REPL
    class GroovyMirror
      def self.load_groovy_dependencies
        unless @loaded
          require File.dirname(__FILE__) + "/../../vendor/groovy"
          require File.dirname(__FILE__) + "/../../vendor/jansi" #more magic
          import 'org.codehaus.groovy.tools.shell.Groovysh'
          import 'org.codehaus.groovy.tools.shell.IO'
          import 'java.io.ByteArrayOutputStream'
          import 'java.io.ByteArrayInputStream'
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
        "Groovysh"
      end

      def grammar_name
        "Groovy"
      end

      def read
        @history
      end

      def clear_history
        @history = @history.split("\n").last
        notify_listeners(:change)
      end

      class Main
        #attr_reader :out
        def initialize
          @out   = ByteArrayOutputStream.new
          @err   = ByteArrayOutputStream.new
          @input = ByteArrayInputStream.new(Java::byte[1024].new)
          @shell = Groovysh.new(IO.new(@input,@out,@err))
        end

        def inspect
          "groovy main"
        end

        def execute(cmd)
          @shell.execute(cmd)
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