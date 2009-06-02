module Redcar
  class Cut < Redcar::EditTabCommand
    key  "Ctrl+X"
    icon :CUT
    
    def execute
      if doc.selection?
        tab.view.cut_clipboard
      else
        n = doc.cursor_line
        doc.select(doc.iter(doc.line_start(n)),
                   doc.iter(doc.line_end(n)))
        tab.view.cut_clipboard
      end
    end
  end
end
