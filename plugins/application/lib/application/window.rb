
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
      create_notebook
      attach_notebook_listeners
    end
      
    def create_notebook
      @notebook = Redcar::Notebook.new
    end
    
    def attach_notebook_listeners
      @notebook.add_listener(:tab_focussed) do |tab|
        notify_listeners(:tab_focussed, tab)
      end
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
    
    # Delegates to the new_tab method in the Window's active Notebook.
    def new_tab(*args, &block)
      notebook.new_tab(*args, &block)
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
