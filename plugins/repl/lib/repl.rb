require 'java'
require 'repl/internal_mirror'
require 'thread'

require File.dirname(__FILE__) + "/../vendor/clojure.jar"
require File.dirname(__FILE__) + "/../vendor/clojure-contrib.jar"
require File.dirname(__FILE__) + "/../vendor/org-enclojure-repl-server.jar"
require File.dirname(__FILE__) + "/../vendor/enclojure-wrapper.jar"

include_class 'clojure.lang.Var'
include_class 'clojure.lang.RT'
include_class 'redcar.repl.Wrapper'

module Redcar
  class REPL
    def self.sensitivities
      [
        Sensitivity.new(:open_repl_tab, Redcar.app, false, [:tab_focussed]) do |tab|
          tab and 
          tab.is_a?(EditTab) and 
          tab.edit_view.document.mirror.is_a?(REPL::InternalMirror)
        end
      ]
    end

    def self.keymaps
      osx = Keymap.build("main", :osx) do
        link "Cmd+Shift+M", REPL::RubyOpenREPL
        link "Cmd+M",       REPL::CommitREPL
      end
      
      linwin = Keymap.build("main", [:linux, :windows]) do
        link "Ctrl+Shift+M", REPL::RubyOpenREPL
        link "Ctrl+M",       REPL::CommitREPL
      end
      
      [linwin, osx]
    end
    
    def self.menus
      Menu::Builder.build do
        sub_menu "Plugins" do
          sub_menu "REPL" do
            item "Open Ruby REPL",    REPL::RubyOpenREPL
            item "Open Clojure REPL", REPL::ClojureOpenREPL
            item "Execute", REPL::CommitREPL
          end
        end
      end
    end
    
    class OpenREPL < Command
      
      def open_repl send_receive
        tab = win.new_tab(Redcar::EditTab)
        edit_view = tab.edit_view
        edit_view.document.mirror = REPL::InternalMirror.new send_receive
        edit_view.cursor_offset = edit_view.document.length
        tab.focus
      end
    end

    class ClojureSendReceive
      def initialize
        @repl_wrapper = Wrapper.new 
        @mutex = Mutex.new
	@history = ""
	
	@thread = Thread.new do
          loop do
            str = @repl_wrapper.getResult
	    puts str
            @mutex.synchronize do
              @history += "\n" + str
            end
	    @parent.notify_listeners(:change) if !@parent.nil?
          end
        end
      end
      
      def set_parent parent
	@parent = parent
	@parent.notify_listeners(:change)
      end

      def get_result
        @mutex.synchronize do
          @history
        end
      end

      def send_to_repl expr
        @mutex.synchronize do
          @history += expr
        end
        @repl_wrapper.sendToRepl(expr)
      end

    end

    class InternalSendReceive

      def initialize
        @history = "=> "
	@binding = binding
      end
      
      def format_error(e)
        backtrace = e.backtrace.reject{|l| l =~ /internal_mirror/}
        backtrace.unshift("(repl):1")
        "#{e.class}: #{e.message}\n        #{backtrace.join("\n        ")}"
      end

      def get_result
        @history
      end
      
      def set_parent parent
	@parent = parent
      end

      def send_to_repl expr
        @history += expr
        begin
          @history += "\n" + eval(expr, @binding).inspect + "\n=> "
        rescue Object => e
          @history += format_error(e)
        end
	@parent.notify_listeners(:change) if !@parent.nil?
      end
    end

    class RubyOpenREPL < OpenREPL
      def execute
	open_repl InternalSendReceive.new
      end
    end
    
    class ClojureOpenREPL < OpenREPL
      def execute
	open_repl ClojureSendReceive.new
      end
    end
    
    class ReplCommand < Command
      sensitize :open_repl_tab
    end
    
    class CommitREPL < ReplCommand
      
      def execute
        edit_view = win.focussed_notebook.focussed_tab.edit_view
        edit_view.document.save!
        edit_view.cursor_offset = edit_view.document.length
        edit_view.scroll_to_line(edit_view.document.line_count)
      end
    end
  end
end


