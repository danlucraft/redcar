
module Redcar
  class IndentRightCommand < ChangeIndentCommand
    key "Ctrl+]"
    
    def indent_line(line_ix)
      if Redcar::Preference.get("Editing/Use spaces instead of tabs").to_bool
        num_spaces = Redcar::Preference.get("Editing/Indent size").to_i
        string = " "*num_spaces
      else
        string = "\t"
      end
      doc.insert(doc.line_start(line_ix), string)
    end
  end
end
