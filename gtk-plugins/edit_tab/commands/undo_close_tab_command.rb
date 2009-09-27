module Redcar
  class UndoCloseEditTabCommand < Redcar::Command
    key "Ctrl+Shift+T"
    sensitive :closed_edit_tab
    
    def execute
      hash = Redcar::EditTabPlugin.closed_tabs.pop
      Redcar::OpenTabCommand.new(hash[:filename]).do
    end
  end
end
