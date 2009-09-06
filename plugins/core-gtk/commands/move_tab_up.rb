
module Redcar
  class MoveTabUp < Redcar::TabCommand
    key "Ctrl+Shift+Page_Down"
    
    def execute
      tab.move_up
    end
  end
end

