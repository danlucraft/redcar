require 'java'
require 'thread'

require File.dirname(__FILE__) + "/repl_mirror.rb"
require File.dirname(__FILE__) + "/../../vendor/clojure.jar"
require File.dirname(__FILE__) + "/../../vendor/clojure-contrib.jar"
require File.dirname(__FILE__) + "/../../vendor/org-enclojure-repl-server.jar"
require File.dirname(__FILE__) + "/../../vendor/enclojure-wrapper.jar"

include_class 'clojure.lang.Var'
include_class 'clojure.lang.RT'
include_class 'redcar.repl.Wrapper'

module Redcar
  class REPL
    class ClojureMirror
      include Redcar::REPL::ReplMirror
      
      def initialize
	
        # required by ReplMirror
        @prompt = "=>"
        
        @repl_wrapper = Wrapper.new 
        @mutex = Mutex.new
        @history = "# Clojure REPL\n"
	
        @thread = Thread.new do
          loop do
            str = @repl_wrapper.getResult
            @mutex.synchronize do
              @history += "\n" if @history != ""
              @history += str
            end
            Redcar.update_gui do
              notify_listeners(:change)
            end
          end
        end
	
      end

      def title
        "Clojure REPL"
      end
      
      # Get the complete history as a pretty formatted string.
      #
      # @return [String]
      def read
        @mutex.synchronize do
          @history
        end
      end
         
      def clear_history
        @mutex.synchronize do
          @history = @history.split("\n").last
        end
        notify_listeners(:change)
      end

      private
      
      def send_to_repl expr
        @mutex.synchronize do
          @history += expr
        end
        @repl_wrapper.sendToRepl(expr)
      end   
    end
  end
end
