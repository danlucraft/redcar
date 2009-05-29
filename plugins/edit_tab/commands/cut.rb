module Redcar
  class Cut < Redcar::EditTabCommand
    key  "Ctrl+X"
    icon :CUT
    
    def execute
      if (cl = Redcar::App.clipboard).wait_is_text_available?
        str = cl.wait_for_text
        if(Redcar::App.prev_clip == nil)
          Redcar::App.init_clipboard_history
        end
        Redcar::App.prev_clip.push(str)
      end
      
      if(Redcar::App.next_clip != nil)
        if(Redcar::App.next_clip.size > 0)
          0.upto(Redcar::App.next_clip.size){
            if(to_prev = Redcar::App.next_clip.pop())
              Redcar::App.prev_clip.push(to_prev) 
            end
          }
        end
      end
      
      if doc.selection?
        tab.view.cut_clipboard
      else
        n = doc.cursor_line
        doc.select(doc.iter(doc.line_start(n)),
                   doc.iter(doc.line_end(n)))
        tab.view.cut_clipboard
      end
    end
  end
end
