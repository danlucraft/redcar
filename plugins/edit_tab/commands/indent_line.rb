module Redcar
  class IndentLine < Redcar::EditTabCommand
    key "Super+Alt+["

    def execute
      tab.view.indent_line(doc.cursor_line)
    end
  end
end
