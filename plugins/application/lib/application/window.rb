
module Redcar
  class Window
    include Redcar::Model
    include Redcar::Observable
    
    # All instantiated windows
    def self.all
      @all ||= []
    end

    attr_reader :notebooks, :notebook_orientation

    def initialize
      Window.all << self
      @visible = false
      @notebooks = []
      create_notebook
      @notebook_orientation = :horizontal
      self.title = "Redcar"
    end
      
    # Create a new notebook in this window.
    #
    # @events [(:new_notebook, notebook)]
    def create_notebook
      return if @notebooks.length == 2
      notebook = Redcar::Notebook.new
      @notebooks << notebook
      if @notebooks.length == 1
        self.focussed_notebook = notebook
      end
      attach_notebook_listeners(notebook)
      notify_listeners(:new_notebook, notebook)
    end
    
    def attach_notebook_listeners(notebook)
      notebook.add_listener(:tab_focussed) do |tab|
        notify_listeners(:tab_focussed, tab)
      end
    end
    
    def close_notebook
      return if @notebooks.length == 1
      first_notebook, second_notebook = *@notebooks
      second_notebook.tabs.each do |tab|
        first_notebook.grab_tab_from(second_notebook, tab)
      end
      @notebooks.delete(second_notebook)
      notify_listeners(:notebook_removed, second_notebook)
    end

    def title
      @title
    end
    
    def title=(value)
      @title = value
      notify_listeners(:title_changed, @title)
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
      focussed_notebook.new_tab(*args, &block)
    end
    
    def focussed_notebook
      @focussed_notebook
    end
    
    def focussed_notebook=(notebook)
      p [:focussed_notebook, notebook]
      @focussed_notebook = notebook
    end
    
    attr_reader :menu

    def menu=(menu)
      @menu = menu
      notify_listeners(:menu_changed, menu)
    end
    
    # Sets the orientation of the notebooks.
    #
    # @param [:horizontal, :vertical] 
    def notebook_orientation=(key)
      @notebook_orientation = key
      notify_listeners(:notebook_orientation_changed, key)
    end
    
    # Sets the orientation of the notebooks to whatever it is not currently.
    def rotate_notebooks
      if notebook_orientation == :horizontal
        self.notebook_orientation = :vertical
      else
        self.notebook_orientation = :horizontal
      end
    end
    
    def inspect
      "#<Redcar::Window \"#{title}\">"
    end
  end
end
