module Redcar
  class Undo < Redcar::EditTabCommand
    key  "Ctrl+Z"
    icon :UNDO
    
    def execute
      tab.view.undo
    end
  end
end

