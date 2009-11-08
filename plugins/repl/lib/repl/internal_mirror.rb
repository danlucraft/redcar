
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
          str << prompt
          str << command
          str << "\n" + output_pointer
          str << result
          str << "\n"
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
        result = eval(command)
        @results << result.inspect
        notify_listeners(:change)
      end

      def title
        "(internal).rb"
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
    end
  end
end
