module Redcar
  class PastePrevious < Redcar::EditTabCommand
    key  "Ctrl+Shift+V"
    icon :PASTE
    
    def execute
      if(Redcar::App.prev_clip != nil)
        prev_text = Redcar::App.prev_clip.pop()
        
        if(prev_text != nil)
          #push current clipboard object onto next paste stack if it exists
          if (cl = Redcar::App.clipboard).wait_is_text_available?
            next_text = cl.wait_for_text
            Redcar::App.next_clip.push(next_text)     
          end
          
          cl.set_text(prev_text)
          str = cl.wait_for_text
          n = str.scan("\n").length+1
          l = doc.cursor_line
          doc.delete_selection
          doc.insert_at_cursor(str)
          if n > 1 and Redcar::Preference.get("Editing/Indent pasted text").to_bool
            n.times do |i|
              tab.view.indent_line(l+i)
            end
          end
        end
      end
    end
  end
end
