require File.dirname(__FILE__) + "/repl_mirror.rb"

module Redcar
  class REPL
    class RubyMirror
      include Redcar::REPL::ReplMirror
      
      def initialize
	@prompt = ">>"
	@history = @prompt + " "
	@binding = binding
      end

      def title
        "Ruby REPL"
      end
      
      # Get the complete history as a pretty formatted string.
      #
      # @return [String]
      def read
        @history
      end

      private
      
      def format_error(e)
        backtrace = e.backtrace.reject{|l| l =~ /internal_mirror/}
        backtrace.unshift("(repl):1")
        "#{e.class}: #{e.message}\n        #{backtrace.join("\n        ")}"
      end
      
      def send_to_repl expr
        @history += expr + "\n"
        begin
          @history += "=> " + eval(expr, @binding).inspect
        rescue Object => e
          @history += "x> " + format_error(e)
        end
	@history += "\n" + @prompt + " "
      end
            
    end
  end
end
