module Redcar
  class ShowScope < Redcar::EditTabCommand
    key "Super+Shift+P"

    def execute
      if root = tab.view.parser.root
        scope = root.scope_at(TextLoc(doc.cursor_line, doc.cursor_line_offset))
      end
      #         puts "scope_at_cursor: #{scope.inspect}"
      # #         scope.root.display(0)
      inner = scope.pattern and scope.pattern.content_name and
        (doc.cursor_line_offset >= scope.open_end.offset and
         (!scope.close_start or doc.cursor_line_offset < scope.close_start.offset))
      #         p scope.hierarchy_names(inner).join("\n")
      tab.view.tooltip_at_cursor(scope.hierarchy_names(inner).join("\n"))
    end
  end
end
