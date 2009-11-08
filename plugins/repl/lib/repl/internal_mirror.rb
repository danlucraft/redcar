
module Redcar
  class REPL
    class InternalMirror
      class Main
        def initialize
          @binding = binding
        end
        
        def inspect
          "main"
        end
        
        def execute(command)
          eval(command, @binding)
        end
      end
      
      include Redcar::EditView::Mirror
      
      attr_reader :history, :results
      
      def initialize
        @history, @results, @instance = [], [], Main.new
      end
      
      def read
        str = message
        @history.zip(@results) do |command, result|
          str << prompt + command + "\n" + output_pointer + result + "\n"
        end
        str << prompt
      end

      def exists?
        true
      end

      def changed?
        false
      end

      def commit(contents)
        command = contents.split(prompt).last
        @history << command
        begin
          result = @instance.execute(command).inspect
        rescue Object => e
          result = format_error(e)
        end
        @results << result
        notify_listeners(:change)
      end

      def title
        "(internal)"
      end
      
      private
      
      def message
        "# Redcar REPL\n\n"
      end
      
      def prompt
        ">> "
      end
      
      def output_pointer
        "=> "
      end
      
      def format_error(e)
        backtrace = e.backtrace.reject{|l| l =~ /internal_mirror/}
        backtrace.unshift("(repl):1")
        "#{e.class}: #{e.message}\n        #{backtrace.join("\n        ")}"
      end
    end
  end
end
