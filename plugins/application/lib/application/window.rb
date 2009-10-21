
module Redcar
  class Window
    include Redcar::Model
    include Redcar::Observable
    
    # All instantiated windows
    def self.all
      @all ||= []
    end

    attr_reader :notebook

    def initialize
      Window.all << self
      @visible = false
      @notebook = Redcar::Notebook.new
    end

    def title
      "Redcar"
    end
    
    def show
      @visible = true
      notify_listeners(:show)
    end
    
    def visible?
      @visible
    end
    
    # Creates a new tab in this window's Notebook, of class tab_class. Returns
    # the tab.
    #
    # Events: new_tab (tab)
    def new_tab(tab_class)
      tab = tab_class.new
      notify_listeners(:new_tab, tab) do
        notebook << tab
      end
      tab
    end
    
    attr_reader :menu

    def menu=(menu)
      @menu = menu
      notify_listeners(:menu_changed, menu)
    end
    
    def inspect
      "#<Redcar::Window \"#{title}\">"
    end
  end
end
