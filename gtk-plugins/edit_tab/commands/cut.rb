module Redcar
  class Cut < Redcar::EditTabCommand
    key  "Ctrl+X"
    icon :CUT
    
    def execute
      if doc.selection?
        str = doc.selection
        tab.view.cut_clipboard
      else
        n = doc.cursor_line
        doc.select(doc.iter(doc.line_start(n)),
                   doc.iter(doc.line_end(n)))
        str = doc.selection
        tab.view.cut_clipboard
      end
      
      if(Redcar::App.paste_history == nil)
        Redcar::App.init_paste_history
        Redcar::App.paste_history.push_with_limit(str)
      else
        if(Redcar::App.paste_history.last != str)
          Redcar::App.paste_history.push_with_limit(str)
        end
      end
    end
  end
end
