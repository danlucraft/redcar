module Redcar
  class Tab
    include Redcar::Model
    include Redcar::Observable
    
    attr_reader :notebook
    
    def initialize(notebook)
      @notebook = notebook
      @title    = "unknown"
    end
    
    # Close the tab (remove it from the Notebook).
    #
    # Events: close
    def close
      notify_listeners(:close)
      @notebook.remove_tab!(self)
    end
    
    # Focus the tab within the notebook, and gives the keyboard focus to the 
    # contents of the tab, if appropriate.
    #
    # Events: focus
    def focus
      notify_listeners(:focus)
    end
    
    def title
      @title
    end
    
    def title=(title)
      @title = title
      notify_listeners(:changed_title, title)
    end
    
    def inspect
      "#<#{self.class.name} \"#{title}\">"
    end
    
    # Sets the notebook of the tab. Should not be called from user code.
    def set_notebook(notebook)
      @notebook = notebook
    end
  end
end
