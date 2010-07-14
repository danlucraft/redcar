
module Redcar
  class AutoIndenter
    
    class IndentCommand < Redcar::EditTabCommand
      
      def execute
        if doc.selection?
          selection = true
          start_line, end_line = *[doc.selection_line, doc.cursor_line].sort
        else
          selection = false
          start_line = end_line = doc.cursor_line
        end
        rules = AutoIndenter.rules_for_scope(doc.cursor_scope)
        analyzer = Analyzer.new(rules, doc, doc.edit_view.tab_width, doc.edit_view.soft_tabs?)
        indentation = doc.indentation
        start_line.upto(end_line) do |line_ix|
          indentation.set_level(line_ix, analyzer.calculate_for_line(line_ix, false))
          indentation.trim_trailing_whitespace(line_ix)
        end
        
        return unless selection
        
        start_offset = doc.offset_at_line(start_line)
        if end_line == doc.line_count - 1
          end_offset = doc.length
        else
          end_offset = doc.offset_at_line(end_line + 1)
        end
        doc.set_selection_range(start_offset, end_offset)
      end
    end
  end
end
