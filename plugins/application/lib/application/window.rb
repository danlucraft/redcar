
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
    
    def new_tab(tab_class)
      tab = tab_class.new
      notify_listeners(:new_tab, tab) do
        notebook << tab
      end
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
