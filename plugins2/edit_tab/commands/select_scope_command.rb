
module Redcar
  class SelectScopeCommand < Redcar::EditTabCommand
    key "Ctrl+Alt+B"
    
    def execute
      doc.select_current_scope
    end
  end
end
