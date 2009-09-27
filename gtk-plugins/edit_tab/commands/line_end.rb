module Redcar
  class LineEnd < Redcar::EditTabCommand
    key  "Ctrl+E"
    icon :GO_FORWARD
    
    def execute
      doc.place_cursor(doc.line_end1(doc.cursor_line))
    end
  end
end

