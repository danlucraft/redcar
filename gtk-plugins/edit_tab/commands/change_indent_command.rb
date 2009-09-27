
module Redcar
  class ChangeIndentCommand < Redcar::EditTabCommand
    
    def execute
      if doc.selection?
        start_line_ix, end_line_ix = *[doc.selection_iter.line, doc.cursor_iter.line].sort
        if doc.cursor_iter == doc.line_start(end_line_ix)
          end_line_ix -= 1
        end
        start_line_ix.upto(end_line_ix) do |line_ix|
          indent_line(line_ix)
        end
      else
        indent_line(doc.cursor_line)
      end
    end
    
  end
end
