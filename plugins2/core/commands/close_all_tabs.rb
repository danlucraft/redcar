
module Redcar
  class CloseAllTabs < Redcar::TabCommand
    key "Ctrl+Super+W"
    icon :CLOSE
    
    def execute
      win.tabs.each &:close
    end
  end
end
