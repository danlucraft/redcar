
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
    
    class CommitREPL < Command
      key :linux   => "Ctrl+M",
          :osx     => "Cmd+M",
          :windows => "Ctrl+M"

      def execute
        edit_view = win.notebook.focussed_tab.edit_view
        edit_view.document.save!
        edit_view.cursor_offset = edit_view.document.length
      end
    end
  end
end