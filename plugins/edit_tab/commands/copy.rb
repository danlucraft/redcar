module Redcar
  class Copy < Redcar::EditTabCommand
    key  "Ctrl+C"
    icon :COPY
    
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
          if(to_prev = Redcar::App.next_clip.pop())
            Redcar::App.prev_clip.push(to_prev) 
          end
        end
      end
      
      if doc.selection?
        tab.view.copy_clipboard
      else
        n = doc.cursor_line
        c = doc.cursor_offset
        doc.select(doc.iter(doc.line_start(n)),
                   doc.iter(doc.line_end(n)))
        tab.view.copy_clipboard
        doc.cursor = c
      end
    end
  end
end

