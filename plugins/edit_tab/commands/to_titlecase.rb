module Redcar
  class ToTitlecase < Redcar::EditTabCommand
    key "Ctrl+Alt+U"
    
    def execute
      if doc.selection?
        curr_sel = doc.selection
        conv = String.new()
        curr_sel.each(' '){|word| conv += word.capitalize}
        doc.replace_selection(conv)
      end
    end  
  end
end
