
module Redcar
  class MoveTabUp < Redcar::TabCommand
    key "Ctrl+Shift+Page_Up"
    
    def execute
      tab.move_up
    end
  end
end

