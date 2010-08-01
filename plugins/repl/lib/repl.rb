require 'repl/ruby_mirror'
require 'repl/clojure_mirror'
require 'repl/repl_mirror'

module Redcar
  class REPL
    def self.sensitivities
      [
        Sensitivity.new(:open_repl_tab, Redcar.app, false, [:tab_focussed]) do |tab|
          tab and 
          tab.is_a?(EditTab) and 
          tab.edit_view.document.mirror.is_a?(REPL::ReplMirror)
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
            item "Clear History", REPL::ClearHistoryREPL
          end
        end
      end
    end
    
    class OpenREPL < Command
      
      def open_repl mirror
        tab = win.new_tab(Redcar::EditTab)
        edit_view = tab.edit_view  
        edit_view.document.mirror = mirror
        edit_view.cursor_offset = edit_view.document.length
        tab.focus
        
        mirror.add_listener(:change) do
          edit_view.cursor_offset = edit_view.document.length
          edit_view.scroll_to_line(edit_view.document.line_count)
        end
        
      end
    end

    class RubyOpenREPL < OpenREPL
      def execute
        open_repl RubyMirror.new
      end
    end
    
    class ClojureOpenREPL < OpenREPL
      def execute
        open_repl ClojureMirror.new
      end
    end
    
    class ReplCommand < Command
      sensitize :open_repl_tab
    end
    
    class CommitREPL < ReplCommand
      
      def execute
        edit_view = win.focussed_notebook.focussed_tab.edit_view
        edit_view.document.save!
      end
    end
    
    class ClearHistoryREPL < ReplCommand
      
      def execute
        mirror = win.focussed_notebook.focussed_tab.edit_view.document.mirror
        mirror.clear_history
      end
    end
    
  end
end


