
module Redcar
  class Window
    include Redcar::Model
    include Redcar::Observable
    
    # All instantiated windows
    def self.all
      @all ||= []
    end

    attr_reader :notebooks, :notebook_orientation
    attr_reader :treebook
    attr_reader :speedbar
    
    def initialize
      Window.all << self
      @visible   = false
      @notebooks = []
      @notebook_orientation = :horizontal
      create_notebook
      @treebook = Treebook.new
      @speedbar = nil
      self.title = "Redcar"
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
        if tab
          self.focussed_notebook = tab.notebook
        else
          new_notebook = self.notebooks.sort_by {|nb| nb.tabs.length}.last
          if new_tab = new_notebook.focussed_tab
            new_notebook.focussed_tab.focus
          end
        end
      end
      notebook.add_listener(:tab_closed) do
        notify_listeners(:tab_closed)
      end
      notebook.add_listener(:focussed_tab_changed) do |tab|
        if notebook == focussed_notebook
          notify_listeners(:focussed_tab_changed, tab)
        end
      end
      notebook.add_listener(:focussed_tab_selection_changed) do |tab|
        if notebook == focussed_notebook
          notify_listeners(:focussed_tab_selection_changed, tab)
        end
      end
    end
    
    def close_notebook
      return if @notebooks.length == 1
      first_notebook, second_notebook = *@notebooks
      second_notebook.tabs.each do |tab|
        first_notebook.grab_tab_from(second_notebook, tab)
      end
      @notebooks.delete(second_notebook)
      self.focussed_notebook = first_notebook
      notify_listeners(:notebook_removed, second_notebook)
    end
    
    def focussed_notebook
      @focussed_notebook
    end
    
    def focussed_notebook=(notebook)
      if notebook != @focussed_notebook
        set_focussed_notebook(notebook)
        notify_listeners(:notebook_focussed, notebook)
      end
    end
    
    def set_focussed_notebook(notebook)
      @focussed_notebook = notebook
    end
    
    def nonfocussed_notebook
      @notebooks.find {|nb| nb != @focussed_notebook }
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
    
    # Delegates to the new_tab method in the Window's active Notebook.
    def new_tab(*args, &block)
      focussed_notebook.new_tab(*args, &block)
    end
    
    attr_reader :menu

    def menu=(menu)
      @menu = menu
      notify_listeners(:menu_changed, menu)
    end

    def popup_menu(menu)
      notify_listeners(:popup_menu, menu)
    end
    
    # Focus the Window.
    def focus
      treebook.refresh_trees
      notify_listeners(:focussed, self)
    end

    # LINUXTODO: should close the app if it is the last window
    def close      
      notify_listeners(:about_to_close, self)
      notebooks.each do |notebook| 
        notebook.tabs.each {|tab| tab.close }
      end
      if notebooks.length > 1
        close_notebook
      end
      notify_listeners(:closed, self)
    end
    
    def inspect
      "#<Redcar::Window \"#{title}\">"
    end
    
    def open_speedbar(speedbar)
      if @speedbar
        close_speedbar
      end
      @speedbar = speedbar
      notify_listeners(:speedbar_opened, speedbar)
    end
    
    def close_speedbar
      notify_listeners(:speedbar_closed, @speedbar)
      @speedbar = nil
      if tab = focussed_notebook.focussed_tab
        tab.focus
      end
    end
  end
end
