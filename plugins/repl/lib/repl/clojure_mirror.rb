
module Redcar
  class REPL
    class ClojureMirror < ReplMirror
      
      def title
        "Clojure REPL"
      end
      
      def grammar_name
        "Clojure REPL"
      end
      
      def initial_preamble
        "# Clojure REPL\n\nuser=>"
      end
      
      def prompt
        "user=>"
      end
      
      def evaluator
        @evaluator ||= ClojureMirror::Evaluator.new(self)
      end
      
      def entered_expression(contents)
        if contents.split("\n").last =~ /=>\s+$/
          ""
        else
          contents.split("=>").last.strip
        end
      end
      
      def format_error(e)
        "ERROR: #{e.message}\n\n#{e.backtrace.join("\n")}"
      end

      class Evaluator
        attr_reader :wrapper
        
        def self.load_clojure_dependencies
          unless @loaded
            require File.join(Redcar.asset_dir, "clojure.jar")
            require File.join(Redcar.asset_dir, "clojure-contrib.jar")
            require File.join(Redcar.asset_dir, "org-enclojure-repl-server.jar")
            require File.dirname(__FILE__) + "/../../vendor/enclojure-wrapper.jar"
            
            import 'redcar.repl.Wrapper'
            @loaded = true
          end
        end

        def initialize(mirror)
          ClojureMirror::Evaluator.load_clojure_dependencies
          @mirror = mirror
          @wrapper ||= begin
            wrapper = Wrapper.new 
            
            @thread = Thread.new do
              loop do
                output = wrapper.getResult
                output =~ /^(.*)\nuser=> /
                @result = $1
              end
            end
            
            wrapper
          end
        end
        
        def execute(expr)
          wrapper.sendToRepl(expr)
          true until @result
          str = @result
          @result = nil
          str
        end
      end
    end
  end
end
