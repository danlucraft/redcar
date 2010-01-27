
require 'application/command/executor'
require 'application/command/history'
require 'application/sensitive'
require 'application/sensitivity'

require 'application/clipboard'
require 'application/command'
require 'application/dialog'
require 'application/dialogs/filter_list_dialog'
require 'application/menu'
require 'application/menu/item'
require 'application/menu/builder'
require 'application/notebook'
require 'application/speedbar'
require 'application/tab'
require 'application/tab/command'
require 'application/treebook'
require 'application/window'

module Redcar
  class << self
    attr_accessor :app, :history
    attr_reader :gui
  end

  # Set the application GUI.
  def self.gui=(gui)
    raise "can't set gui twice" if @gui
    @gui = gui
  end
  
  class Application
    NAME = "Redcar"
    
    include Redcar::Model
    include Redcar::Observable
    
    def self.start
      Redcar.app     = Application.new
      Redcar.history = Command::History.new
    end
    
    def self.sensitivities
      [ 
        Sensitivity.new(:open_tab, Redcar.app, false, [:focussed_window, :tab_focussed]) do |tab|
          if win = Redcar.app.focussed_window
            win.focussed_notebook.focussed_tab
          end
        end,
        Sensitivity.new(:single_notebook, Redcar.app, true, [:focussed_window, :notebook_change]) do
          if win = Redcar.app.focussed_window
            win.notebooks.length == 1
          end
        end,
        Sensitivity.new(:multiple_notebooks, Redcar.app, false, [:focussed_window, :notebook_change]) do
          if win = Redcar.app.focussed_window
            win.notebooks.length > 1
          end
        end,
        Sensitivity.new(:other_notebook_has_tab, Redcar.app, false, 
                        [:focussed_window, :focussed_notebook, :notebook_change, :tab_closed]) do
          if win = Redcar.app.focussed_window and notebook = win.nonfocussed_notebook
            notebook.tabs.any?
          end
        end
      ]
    end
    
    attr_reader :clipboard
    
    def initialize
      @windows = []
      @window_handlers = Hash.new {|h,k| h[k] = []}
      create_clipboard
    end
    
    def create_clipboard
      @clipboard       = Clipboard.new("application")
      @clipboard.add_listener(:added) { notify_listeners(:clipboard_added) }
    end
    
    # Immediately halts the gui event loop.
    def quit
      Redcar.gui.stop
    end
    
    # Return a list of all open windows
    def windows
      @windows
    end

    # Create a new Application::Window, and the controller for it.
    def new_window
      new_window = Window.new
      windows << new_window
      notify_listeners(:new_window, new_window)
      attach_window_listeners(new_window)
      new_window.menu = menu
      new_window.show
      set_focussed_window(new_window)
      new_window
    end
    
    # Removes a window from this Application. Should not be called by user
    # code, use Window#close instead.
    def window_closed(window)
      windows.delete(window)
      if focussed_window == window
        self.focussed_window = windows.first
      end
      @window_handlers[window].each {|h| window.remove_listener(h) }
      @window_handlers.delete(window)
      if windows.length == 0  and [:linux, :windows].include?(Redcar.platform)
        quit
      end
    end
    
    def all_notebooks
      windows.inject([]) { |arr, window| arr << window.notebooks }.flatten
    end
    
    def all_tabs
      all_notebooks.inject([]) { |arr, notebook| arr << notebook.tabs }.flatten
    end
    
    def focussed_window_notebook
      focussed_window.focussed_notebook if focussed_window
    end
    
    def focussed_notebook_tab
      focussed_window_notebook.focussed_tab if focussed_window_notebook
    end
    
    def focussed_tab_edit_view
      focussed_notebook_tab.edit_view if focussed_notebook_tab and focussed_notebook_tab.is_a?(EditTab)
    end
    
    def focussed_edit_view_document
      focussed_tab_edit_view.document if focussed_tab_edit_view
    end
    
    def focussed_document_mirror
      focussed_edit_view_document.mirror if focussed_edit_view_document
    end
    
    def focussed_window
      @focussed_window
    end
    
    def focussed_window=(window)
      set_focussed_window(window)
      notify_listeners(:focussed_window, window)
    end
    
    def set_focussed_window(window)
      @focussed_window = window
    end
    
    attr_reader :menu
    
    # Set the main menu. Causes a redraw of the GUI menu.
    #
    # @param [Menu]
    def menu=(menu)
      @menu = menu
      windows.each do |window|
        window.menu = menu
      end
    end
    
    # Redraw the main menu. Useful if you have modified the main menu
    # instead of setting it afresh.
    def refresh_menu!
      self.menu = @menu
    end
    
    def load_menus
      menu = Menu.new
      Redcar.plugin_manager.loaded_plugins.each do |plugin|
        if plugin.object.respond_to?(:menus)
          menu.merge(plugin.object.menus)
        end
      end
      self.menu = menu
    end
    
    def load_sensitivities
      Redcar.plugin_manager.loaded_plugins.each do |plugin|
        if plugin.object.respond_to?(:sensitivities)
          plugin.object.sensitivities
        end
      end
    end
    
    def attach_window_listeners(window)
      h1 = window.add_listener(:tab_focussed) do |tab|
        notify_listeners(:tab_focussed, tab)
      end
      h2 = window.add_listener(:closed) do |win|
        window_closed(win)
      end
      h3 = window.add_listener(:focussed) do |win|
        self.focussed_window = win
      end
      h4 = window.add_listener(:new_notebook) do |win|
        notify_listeners(:notebook_change)
      end
      h5 = window.add_listener(:notebook_removed) do |win|
        notify_listeners(:notebook_change)
      end
      h6 = window.add_listener(:notebook_focussed) do |win|
        notify_listeners(:focussed_notebook)
      end
      h7 = window.add_listener(:tab_closed) do |win|
        notify_listeners(:tab_closed)
      end
      h8 = window.add_listener(:focussed_tab_changed) do |tab|
        if window == focussed_window
          notify_listeners(:focussed_tab_changed, tab)
        end
      end
      h9 = window.add_listener(:focussed_tab_selection_changed) do |tab|
        if window == focussed_window
          notify_listeners(:focussed_tab_selection_changed, tab)
        end
      end
      @window_handlers[window] << h1 << h2 << h3 << h4 << h5 << h6 << h7 << h8 << h9
    end
  end
end






