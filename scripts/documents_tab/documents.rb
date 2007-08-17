# redcar/scripts/documents
# A tab with a list of open documents.

module Redcar
  class DocumentsTab < Tab
    @@la = nil
    def initialize(pane)
      unless @@la
        Redcar.hook :after_new_tab, :after_tab_close, :after_tab_rename, :tab_modified do |tab|
          Redcar::DocumentsTab.refresh
        end
      end
      @@la ||= []
      @@la << (list = Redcar::GUI::List.new(:type => String, :heading => "name"))
      list.on_double_click do |item|
        Redcar.current_window.find_tab(item).focus
      end
      super(pane, @@la.last.treeview)
      @@la.last.treeview.show_all
      DocumentsTab.refresh
      self.name = "Documents"
    end
    
    def self.refresh
      if @@la
        @@la.each do |list|
          tabs = []
          Redcar.current_window.panes.each do |pane|
            pane.each do |tab|
              tabs << tab
            end
          end
          tab_list = tabs.select{|tab| tab.is_a? TextTab}
          list.replace tab_list.map(&:name)
          tab_list.each_with_index do |tab, i| 
            if tab.modified?
              list.background_colour(i, "#FFCCCC")
            else
              list.background_colour(i, "#FFFFFF") # TODO: should say false to turn colour off
            end
          end
        end
      end
    end
  end
end
