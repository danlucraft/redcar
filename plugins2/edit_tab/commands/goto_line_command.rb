
module Redcar
  class AskGotoLineCommand < Redcar::EditTabCommand
    key "Super+Shift+L"
    norecord
    
    class GotoLineSpeedbar < Redcar::Speedbar
      label "Line:"
      textbox :line_num
      button "Go", nil, "Return" do |sb|
        GotoLineCommand.new(sb.line_num.to_i).do
        sb.close
      end
    end
    
    def execute
      GotoLineSpeedbar.new.show(tab)
    end
  end

  class GotoLineCommand < Redcar::EditTabCommand
    def initialize(line)
      @line = line
    end

    def execute
      doc.cursor = doc.line_start(@line-1)
      view.scroll_to_mark(doc.cursor_mark, 0.0, true, 0.5, 0.5)
    end
  end
end
