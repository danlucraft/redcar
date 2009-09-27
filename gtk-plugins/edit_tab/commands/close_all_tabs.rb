
module Redcar
  class CloseAllTabs < Redcar::TabCommand
    key "Ctrl+Shift+W"
    icon :CLOSE
    sensitive :open_edit_tabs
    
    def execute
      win.collect_tabs(Redcar::EditTab).each(&:close)
    end
  end
end
