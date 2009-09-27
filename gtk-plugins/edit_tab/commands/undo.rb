module Redcar
  class Undo < Redcar::EditTabCommand
    key  "Ctrl+Z"
    icon :UNDO
    
    def execute
      tab.view.undo
      if !tab.document.can_undo?
        tab.modified = false
      end
    end
  end
end

