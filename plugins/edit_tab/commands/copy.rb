module Redcar
  class Copy < Redcar::EditTabCommand
    key  "Ctrl+C"
    icon :COPY
    
    def execute
      if doc.selection?
        tab.view.copy_clipboard
      else
        n = doc.cursor_line
        c = doc.cursor_offset
        doc.select(doc.iter(doc.line_start(n)),
                   doc.iter(doc.line_end(n)))
        tab.view.copy_clipboard
        doc.cursor = c
      end
    end
  end
end

