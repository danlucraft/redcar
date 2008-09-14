module Redcar
  class Redo < Redcar::EditTabCommand
    key  "Shift+Ctrl+Z"
    icon :REDO
    
    def execute
      tab.view.redo
    end
  end
end

