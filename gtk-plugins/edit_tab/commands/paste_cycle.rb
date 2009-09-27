module Redcar
  class PasteCycle < Redcar::EditTabCommand
    key  "Ctrl+Super+V"
    icon :PASTE
    
    @@count = 0
    
    def execute
      if Redcar::App.paste_history
        if Redcar::CommandHistory.last.name == self.class.name
          @@count = @@count+1
          if @@count == Redcar::App.paste_history.size
            return
          end
        else
          @@count = 0
        end
        
        str = Redcar::App.paste_history[-(@@count+1)]
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
      end
    end
  end
end
