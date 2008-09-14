module Redcar
  class KillLine < Redcar::EditTabCommand
    key  "Ctrl+K"
    icon :DELETE

    def execute
      if doc.get_line(doc.cursor_line) == "\n"
        doc.delete(doc.cursor_iter, doc.line_end(doc.cursor_line))
      else
        doc.delete(doc.cursor_iter,
                   doc.line_end1(doc.cursor_line))
      end          
    end
  end
end
