
module Redcar
  class NextTab < Redcar::TabCommand
    key "Ctrl+Page_Down"
    
    def execute
      tab.pane.gtk_notebook.next_page
    end
  end
end

