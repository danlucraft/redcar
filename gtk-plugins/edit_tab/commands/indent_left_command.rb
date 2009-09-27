
module Redcar
  class IndentLeftCommand < ChangeIndentCommand
    key "Super+["
    
    def indent_line(line_ix)
      use_spaces = Redcar::Preference.get("Editing/Use spaces instead of tabs").to_bool
      num_spaces = Redcar::Preference.get("Editing/Indent size").to_i
      line = doc.get_line(line_ix)
      if line[0..0] == "\t"
        line_start = doc.line_start(line_ix)
        to = doc.iter(line_start.offset + 1)
      elsif line[0...num_spaces] == " "*num_spaces
        line_start = doc.line_start(line_ix)
        to = doc.iter(line_start.offset + num_spaces)
      end
      doc.delete(line_start, to) unless line_start == to
    end
  end
end
