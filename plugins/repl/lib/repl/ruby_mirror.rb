require File.dirname(__FILE__) + "/repl_mirror.rb"

module Redcar
  class REPL
    class RubyMirror
      include Redcar::REPL::ReplMirror
      
      def initialize(win)
        
        # required by ReplMirror
        @prompt = ">>"
        @win = win
	
        @history = "# Redcar REPL\n\n#{@prompt} "
        @instance = Main.new
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
      
      class Main
        attr_reader :output
        
        def initialize
          @binding = binding
          @output = nil
        end

        def inspect
          "main"
        end
        
        def execute(command)
          eval(command, @binding).inspect
        end
      end
      
      def format_error(e)
        backtrace = e.backtrace.reject{|l| l =~ /ruby_mirror/}
        backtrace.unshift("(repl):1")
        "#{e.class}: #{e.message}\n        #{backtrace.join("\n        ")}"
      end
      
      def send_to_repl expr
        @history += expr + "\n"
        begin
          @history += "=> " + @instance.execute(expr)
        rescue Object => e
          @history += "x> " + format_error(e)
        end
        @history += "\n" + @prompt + " "
        update_edit_view
      end
            
    end
  end
end
