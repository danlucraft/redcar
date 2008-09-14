
module Redcar
  class PreviousTab < Redcar::TabCommand
    key "Ctrl+Page_Down"
    
    def execute
      tab.pane.gtk_notebook.prev_page
    end
  end
end
