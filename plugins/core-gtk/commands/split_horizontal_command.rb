module Redcar
  class SplitHorizontal < Redcar::Command
    key "Ctrl+2"
    norecord
    
    def execute
      if tab
        tab.pane.split_horizontal
      else
        win.panes.first.split_horizontal
      end
    end
  end
end
