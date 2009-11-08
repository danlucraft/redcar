
module Redcar
  class REPL
    class InternalMirror
      include Redcar::EditView::Mirror
      
      def initialize
        @history = []
        @results = []
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
          result = eval(command).inspect
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
        "#{e.class}: #{e.message}\n        #{e.backtrace.join("\n        ")}"
      end
    end
  end
end
