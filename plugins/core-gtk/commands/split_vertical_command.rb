module Redcar
  class SplitVertical < Redcar::Command
    key "Ctrl+3"
    norecord
    
    def execute
      if tab
        tab.pane.split_vertical
      else
        win.panes.first.split_vertical
      end
    end
  end
end
