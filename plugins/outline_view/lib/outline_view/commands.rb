module Redcar
  class OutlineView
    class OpenOutlineViewCommand < Redcar::EditTabCommand
      
      def execute
        cur_doc = Redcar.app.focussed_window.focussed_notebook_tab.document
        if cur_doc
          OutlineViewDialog.new(cur_doc).open
        end
      end
    end
  end
end
