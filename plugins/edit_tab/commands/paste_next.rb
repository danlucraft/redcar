module Redcar
  class PasteNext < Redcar::EditTabCommand
    key  "Ctrl+Alt+V"
    icon :PASTE
    
    def execute
      if(Redcar::App.next_clip != nil)
        next_text = Redcar::App.next_clip.pop()
        
        if(next_text != nil)
          #push current clipboard object onto previous paste stack if it exists  
          if (cl = Redcar::App.clipboard).wait_is_text_available?   
            prev_text = cl.wait_for_text
            Redcar::App.prev_clip.push(prev_text) 
          end         
          
          cl.set_text(next_text)
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
