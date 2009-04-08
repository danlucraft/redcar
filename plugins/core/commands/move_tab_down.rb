
module Redcar
  class MoveTabDown < Redcar::TabCommand
    key "Ctrl+Shift+Page_Up"
    
    def execute
      tab.move_down
    end
  end
end
