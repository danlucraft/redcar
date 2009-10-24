module Redcar
  #
  # Events: new_tab (tab)
  class Notebook
    include Redcar::Model
    include Redcar::Observable
    
    attr_reader :tabs
    
    def initialize
      @tabs = []
    end
    
    def length
      @tabs.length
    end
    
    # Creates a new tab in this Notebook, of class tab_class. Returns
    # the tab.
    #
    # Events: tab_added (tab)
    def new_tab(tab_class)
      tab = tab_class.new(self)
      notify_listeners(:tab_added, tab) do
        @tabs << tab
      end
      tab
    end
  end
end
