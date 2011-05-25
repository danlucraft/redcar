
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
        doc.edit_view.compound do
          start_line.upto(end_line) do |line_ix|
            indentation.set_level(line_ix, analyzer.calculate_for_line(line_ix, false))
            indentation.trim_trailing_whitespace(line_ix)
          end
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

    class TidyCommand < Redcar::EditTabCommand
      
      def execute
        selection = false
        start_line = 0
        end_line = doc.line_count - 1
        rules = AutoIndenter.rules_for_scope(doc.cursor_scope)
        analyzer = Analyzer.new(rules, doc, doc.edit_view.tab_width, doc.edit_view.soft_tabs?)
        indentation = doc.indentation
        doc.edit_view.compound do
          start_line.upto(end_line) do |line_ix|
            indentation.set_level(line_ix, analyzer.calculate_for_line(line_ix, false))
            indentation.trim_trailing_whitespace(line_ix)
          end
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
