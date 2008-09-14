module Redcar
  class MoveTabDown < Redcar::TabCommand
    key "Ctrl+Shift+Page_Down"
    
    def execute
      tab.move_down
    end
  end
end
