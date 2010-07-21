
module Redcar
  class REPL
    class InternalMirror
      include Redcar::Document::Mirror
                  
      def initialize send_receive
        @send_receive = send_receive
	@send_receive.set_parent self
      end

      def title
        "(internal)"
      end
      
      # Get the complete history of commands and results as a pretty formatted
      # string.
      #
      # @return [String]
      def read
        @send_receive.get_result
      end

      # Execute a new statement. Accepts the entire pretty formatted history,
      # within which it looks for the last statement and executes it.
      #
      # @param [String] a string with at least one prompt and statement in it
      def commit(contents)
        if contents.split("\n").last =~ /=>\s+$/
          command = ""
        else
          command = contents.split('=>').last.strip
        end
        @send_receive.send_to_repl command
      end

      # The Repl always exists because there is no external resource to 
      # represent.
      def exists?
        true
      end

      # The Repl never changes except for after commit operations.
      def changed?
        false
      end

      private
      
      def message
        "# Redcar REPL\n\n"
      end      
            
    end
  end
end
