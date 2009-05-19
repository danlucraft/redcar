module Redcar
  class ToLowercase < Redcar::EditTabCommand
    key "Ctrl+Shift+U"
    
    def execute
      if doc.selection?
        doc.replace_selection((doc.selection).downcase)
      end
    end  
  end
end
