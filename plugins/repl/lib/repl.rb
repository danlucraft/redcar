
require 'repl/internal_mirror'

module Redcar
  class REPL
    class OpenInternalREPL < Command
      
      def execute
        tab = win.new_tab(Redcar::EditTab)
        edit_view = tab.edit_view
        edit_view.document.mirror = InternalMirror.new
        edit_view.cursor_offset = edit_view.document.length
        tab.focus
      end
    end
    
    class ReplCommand < Command
      sensitize :open_repl_tab
    end
    
    def self.start
      Sensitivity.new(:open_repl_tab, Redcar.app, [:tab_focussed]) do |tab|
        tab and 
        tab.is_a?(EditTab) and 
        tab.edit_view.document.mirror.is_a?(REPL::InternalMirror)
      end
    end
    
    class CommitREPL < ReplCommand
      key :linux   => "Ctrl+M",
          :osx     => "Cmd+M",
          :windows => "Ctrl+M"

      def execute
        edit_view = win.notebook.focussed_tab.edit_view
        edit_view.document.save!
        edit_view.cursor_offset = edit_view.document.length
        edit_view.scroll_to_line(edit_view.document.line_count)
      end
    end
  end
end


