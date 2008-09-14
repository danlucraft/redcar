
module Redcar
  class NewTab < Redcar::Command
    key   "Ctrl+N"
    icon  :NEW
    
    def execute
      win.new_tab(EditTab).focus
    end
  end
end
