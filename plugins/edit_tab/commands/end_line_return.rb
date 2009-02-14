module Redcar
  class EndLineReturn < Redcar::EditTabCommand
    key "Ctrl+Return"
    
    def execute
      doc.place_cursor(doc.line_end1(doc.cursor_line))
      doc.insert_at_cursor("\n")
    end
  end
end
