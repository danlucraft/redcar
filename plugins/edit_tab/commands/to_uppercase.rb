module Redcar
  class ToUppercase < Redcar::EditTabCommand
    key "Ctrl+U"

    def execute
      if doc.selection?
        doc.replace_selection((doc.selection).upcase)
      end
    end  
  end
end
