module Redcar
  class Paste < Redcar::EditTabCommand
    key  "Ctrl+V"
    icon :PASTE

    def execute
      if (cl = Redcar::App.clipboard).wait_is_text_available?
        str = cl.wait_for_text
        n = str.scan("\n").length+1
        l = doc.cursor_line
        doc.insert_at_cursor(str)
        if n > 1 and Redcar::Preference.get("Editing/Indent pasted text").to_bool
          n.times do |i|
            tab.indent_line(l+i)
          end
        end
      end
    end
  end
end
