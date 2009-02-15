
module Redcar
  class NewTab < Redcar::Command
    key   "Super+N"
    icon  :NEW
    
    def execute
      tab = win.new_tab(EditTab)
      tab.focus
      tab
    end
  end
end
