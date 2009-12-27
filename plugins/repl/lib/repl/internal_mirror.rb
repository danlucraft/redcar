
module Redcar
  class REPL
    class InternalMirror
      include Redcar::Document::Mirror
      
      attr_reader :history, :results
      
      def initialize
        @history, @results, @instance = [], [], Main.new
      end

      def title
        "(internal)"
      end
      
      # Get the complete history of commands and results as a pretty formatted
      # string.
      #
      # @return [String]
      def read
        str = message
        @history.zip(@results) do |command, result|
          output, is_error = *result
          str << prompt + command + "\n"
          str << (is_error ? error_pointer : output_pointer)
          output.scan(/.{1,80}/).each do |output_line|
            str << output_line + "\n"
          end
        end
        str << prompt
      end

      # Execute a new statement. Accepts the entire pretty formatted history,
      # within which it looks for the last statement and executes it.
      #
      # @param [String] a string with at least one prompt and statement in it
      def commit(contents)
        command = contents.split(prompt).last
        @history << command
        begin
          result, is_error = @instance.execute(command).inspect, false
        rescue Object => e
          result, is_error = format_error(e), true
        end
        @results << [result, is_error]
        notify_listeners(:change)
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
      
      def prompt
        ">> "
      end
      
      def output_pointer
        "=> "
      end
      
      def error_pointer
        "x> "
      end
      
      def format_error(e)
        backtrace = e.backtrace.reject{|l| l =~ /internal_mirror/}
        backtrace.unshift("(repl):1")
        "#{e.class}: #{e.message}\n        #{backtrace.join("\n        ")}"
      end
      
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
    end
  end
end
