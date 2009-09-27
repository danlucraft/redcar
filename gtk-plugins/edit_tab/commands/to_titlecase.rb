module Redcar
  class ToTitlecase < Redcar::EditTabCommand
    key "Ctrl+Alt+U"
    
    def execute
      if doc.selection?
        #convert current selection to titlecase
        curr_sel = doc.selection
        conv = String.new()
        curr_sel.each(' '){|word| conv += word.capitalize}
        doc.replace_selection(conv)
      else
        #convert current line to titlecase
        n = doc.cursor_line
        c = doc.cursor_offset
        doc.select(doc.iter(doc.line_start(n)),
                   doc.iter(doc.line_end(n)))
        curr_sel = doc.selection
        conv = String.new()
        curr_sel.each(' '){|word| conv += word.capitalize}
        doc.replace_selection(conv)
        doc.cursor = c  
      end
    end  
  end
end
