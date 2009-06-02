module Redcar
  class PasteCycle < Redcar::EditTabCommand
    key  "Ctrl+Shift+V"
    icon :PASTE
    
    @@time_since_last = nil
    @@count = 0
    
    def execute
      if(Redcar::App.paste_history != nil)
        if(@@time_since_last != nil)
          if(Redcar::CommandHistory.last.name == self.class.name)
            @@count = @@count+1
            if((Time.now - @@time_since_last) < 1)
              if(@@count == Redcar::App.paste_history.size)
                @@count = 0   
              end
            else 
              @@count = 0
            end         
          end
        end
        
        str = Redcar::App.paste_history[@@count]
        n = str.scan("\n").length+1
        l = doc.cursor_line
        doc.delete_selection
        doc.insert_at_cursor(str)
        doc.select(doc.cursor_offset-str.length, doc.cursor_offset)
        if n > 1 and Redcar::Preference.get("Editing/Indent pasted text").to_bool
          n.times do |i|
            tab.view.indent_line(l+i)
          end
        end
        
        @@time_since_last = Time.now   
      end
    end
  end
end
