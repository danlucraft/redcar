
module Redcar
  class OpenProject < Command
    menu "Project/Open"
    key  "Ctrl+Shift+P"
    
    def execute
      new_tab = win.new_tab(ProjectTab)
      new_tab.focus
#      Redcar.StatusBar.main = "Opened Project tab"
    end
  end
end
