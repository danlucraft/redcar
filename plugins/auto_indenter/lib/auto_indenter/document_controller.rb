
module Redcar
  class AutoIndenter
    class DocumentController
      include Redcar::Document::Controller
      include Redcar::Document::Controller::ModificationCallbacks
      include Redcar::Document::Controller::NewlineCallback

      def disable
        increase_ignore
        result = yield
        decrease_ignore
        result
      end

      alias_method :ignore, :disable

      def ignore?
        @ignore
      end

      def increase_ignore
        @ignore ||= 0
        @ignore += 1
      end

      def decrease_ignore
        @ignore -= 1
        @ignore = nil if @ignore == 0
      end

      def before_modify(start_offset, end_offset, text)
        return if ignore? or in_snippet?

        @start_offset, @end_offset, @text = start_offset, end_offset, text
        line = document.get_line(document.cursor_line)
        rules = AutoIndenter.rules_for_scope(document.cursor_scope)
        @flags = get_flags(line, rules)
      end

      def in_snippet?
        snippet_controller = document.controllers(Snippets::DocumentController).first and
         snippet_controller.in_snippet?
      end

      def get_flags(line, rules)
        [rules.increase_indent?(line), rules.decrease_indent?(line), rules.indent_next_line?(line), rules.unindented_line?(line)]
      end

      def after_modify
        return if ignore? or in_snippet?
        
        start_line_ix = document.line_at_offset(@start_offset)
        end_line_ix   = document.line_at_offset([[@start_offset + @text.length, document.length - 1].min, 0].max)
        if start_line_ix == end_line_ix
          rules = AutoIndenter.rules_for_scope(document.cursor_scope)
          line = document.get_line(start_line_ix)
          if get_flags(line, rules) != @flags
            edit_view = document.edit_view
            analyzer = Analyzer.new(rules, document, edit_view.tab_width, edit_view.soft_tabs?)
            new_indentation = analyzer.calculate_for_line(start_line_ix, true)
            if new_indentation >= 0 and new_indentation < document.indentation.get_level(start_line_ix)
              increase_ignore
              document.indentation.set_level(start_line_ix, new_indentation)
              decrease_ignore
            end
          end
        end
      end

      def after_newline(line_ix)
        return if ignore? or in_snippet?
        
        rules = AutoIndenter.rules_for_scope(document.cursor_scope)
        if line_ix > 0
          indentation   = document.indentation
          current_level = indentation.get_level(line_ix - 1)
          edit_view     = document.edit_view
          analyzer      = Analyzer.new(rules, document, edit_view.tab_width, edit_view.soft_tabs?)
          increase_ignore
          new_level     = analyzer.calculate_for_line(line_ix, true)
          document.compound do
            if analyzer.expand_block?(line_ix)
              line_start = document.offset_at_line(line_ix)
              document.insert(line_start, "\n")
              indentation.set_level(line_ix, analyzer.calculate_for_line(line_ix, true))
              indentation.set_level(line_ix + 1, analyzer.calculate_for_line(line_ix + 1, true))
            else
              indentation.set_level(line_ix, analyzer.calculate_for_line(line_ix, true))
            end
            prefix = indentation.whitespace_prefix(line_ix)
            document.cursor_offset = document.offset_at_line(line_ix) + prefix.length
          end
          decrease_ignore
        end
      end
    end
  end
end




