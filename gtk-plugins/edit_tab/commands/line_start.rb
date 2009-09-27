module Redcar
  class LineStart < Redcar::EditTabCommand
    key  "Ctrl+A"
    icon :GO_BACK
    
    def execute
      doc.place_cursor(doc.line_start(doc.cursor_line))
    end
  end
end
