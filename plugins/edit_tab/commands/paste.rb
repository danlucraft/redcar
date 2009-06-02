module Redcar
  class Paste < Redcar::EditTabCommand
    key  "Ctrl+V"
    icon :PASTE

    def execute
      if (cl = Redcar::App.clipboard).wait_is_text_available?
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
        
        if(Redcar::App.paste_history == nil)
          Redcar::App.init_paste_history
          Redcar::App.paste_history.push(str)
        else
          if(Redcar::App.paste_history.last != str)
            Redcar::App.paste_history.push(str)
          end
        end
      end
    end
  end
end
