module Redcar
  #
  # Events: new_tab (tab)
  class Notebook
    include Redcar::Model
    include Redcar::Observable
    
    def initialize
      @tabs         = []
      @focussed_tab = nil
      @tab_handlers = Hash.new {|h,k| h[k] = [] }
    end
    
    def length
      @tabs.length
    end
    
    def focussed_tab
      @focussed_tab
    end
    
    def tabs
      @tabs.clone
    end
    
    # Creates a new tab in this Notebook, of class tab_class. Returns
    # the tab.
    #
    # Events: tab_added (tab)
    def new_tab(tab_class)
      tab = tab_class.new(self)
      attach_tab_listeners(tab)
      notify_listeners(:tab_added, tab) do
        @tabs << tab
      end
      tab
    end
    
    # Moves a tab from another notebook to this notebook.
    #
    # @param [Redcar::Notebook]
    # @param [Redcar::Tab]
    def grab_tab_from(other_notebook, tab)
      return if other_notebook == self
      other_notebook.remove_tab!(tab)
      @tabs << tab
      tab.set_notebook(self)
      notify_listeners(:tab_moved, other_notebook, self, tab)
      attach_tab_listeners(tab)
    end
    
    # Should not be called by user code. Call tab.close instead.
    def remove_tab!(tab)
      @tabs.delete(tab)
      @tab_handlers[tab].each {|h| tab.remove_listener(h) }
      select_tab!(nil) unless @tabs.any?
    end
    
    # Should not be called by user code. Call tab.focus instead.
    def select_tab!(tab)
      @focussed_tab = tab
      notify_listeners(:tab_focussed, tab)
    end
    
    def inspect
      "#<Redcar::Notebook #{object_id}>"
    end
    
    private
    
    def attach_tab_listeners(tab)
      @tab_handlers[tab] << tab.add_listener(:focussed) do
        select_tab!(tab)
      end
    end
  end
end
