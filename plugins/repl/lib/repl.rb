
require 'repl/internal_mirror'

module Redcar
  class REPL
    class OpenInternalREPL < Command
      
      def execute
        tab = win.new_tab(Redcar::EditTab)
        tab.edit_view.document.mirror = InternalMirror.new
        tab.focus
      end
    end
  end
end