module Redcar
  class IndentLine < Redcar::EditTabCommand
    key "Ctrl+Alt+["

    def execute
      tab.view.indent_line(doc.cursor_line)
    end
  end
end
