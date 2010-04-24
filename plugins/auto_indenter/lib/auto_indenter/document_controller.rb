
module Redcar
  class AutoIndenter
    class DocumentController
      include Redcar::Document::Controller
      include Redcar::Document::Controller::ModificationCallbacks
      include Redcar::Document::Controller::NewlineCallback
      
      def before_modify(start_offset, end_offset, text)
        return if @ignore
        @start_offset, @end_offset, @text = start_offset, end_offset, text
      end
      
      def after_modify
        return if @ignore
        start_line_ix = document.line_at_offset(@start_offset)
        end_line_ix   = document.line_at_offset(@start_offset + @text.length)
        if start_line_ix == end_line_ix
          rules = AutoIndenter.rules_for_scope(document.cursor_scope)
          p rules
          line = document.get_line(start_line_ix)
          if rules.decrease_indent?(line)
            edit_view = document.edit_view
            analyzer = Analyzer.new(rules, document, edit_view.tab_width, edit_view.soft_tabs?)
            @ignore = true
            document.indentation.set_level(start_line_ix, analyzer.calculate_for_line(start_line_ix))
            @ignore = false
          end
        end
      end
      
      def after_newline(line_ix)
        rules = AutoIndenter.rules_for_scope(document.cursor_scope)
        if line_ix > 0
          indentation = document.indentation
          current_level = indentation.get_level(line_ix - 1)
          edit_view = document.edit_view
          analyzer = Analyzer.new(rules, document, edit_view.tab_width, edit_view.soft_tabs?)
          indentation.set_level(line_ix, analyzer.calculate_for_line(line_ix))
          prefix = indentation.whitespace_prefix(line_ix)
          document.cursor_offset = document.offset_at_line(line_ix) + prefix.length
        end
      end
    end
  end
end