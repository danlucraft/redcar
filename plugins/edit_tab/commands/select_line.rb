module Redcar
  class SelectLine < Redcar::EditTabCommand
    key  "Ctrl+Shift+L"

    def execute
      doc.select(doc.line_start(doc.cursor_line),
                 doc.line_end(doc.cursor_line))
    end
  end
end
