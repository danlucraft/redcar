module Redcar
  class Copy < Redcar::EditTabCommand
    key  "Ctrl+C"
    icon :COPY
    
    def execute
      if doc.selection?
        str = doc.selection
        tab.view.copy_clipboard
      else
        n = doc.cursor_line
        c = doc.cursor_offset
        doc.select(doc.iter(doc.line_start(n)),
                   doc.iter(doc.line_end(n)))
        str = doc.selection
        tab.view.copy_clipboard
        doc.cursor = c
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

