
require 'application/command/executor'
require 'application/command/history'
require 'application/sensitive'
require 'application/sensitivity'

require 'application/clipboard'
require 'application/command'
require 'application/dialog'
require 'application/dialogs/filter_list_dialog'
require 'application/event_spewer'
require 'application/keymap'
require 'application/keymap/builder'
require 'application/menu'
require 'application/menu/item'
require 'application/menu/lazy_menu'
require 'application/menu/builder'
require 'application/menu/builder/group'
require 'application/notebook'
require 'application/speedbar'
require 'application/tab'
require 'application/tab/command'
require 'application/treebook'
require 'application/window'

module Redcar
  # A Redcar process contains one Application instance. The application instance
  # (the app) contains:
  #
  #  * an array of {Redcar::Window} objects and handles creating new Windows.
  #  * a {Redcar::Clipboard}
  #  * a {Redcar::Command::History}
  #
  # A lot of events in Redcar bubble up through the app, which gives plugins
  # one place to hook into Redcar events.
  class Application
    NAME = "Redcar"
    
    include Redcar::Model
    include Redcar::Observable
    
    def self.start
      Redcar.app = Application.new
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
    
    attr_reader :clipboard, :keymap, :menu, :history, :task_queue
    
    # Create an application instance with a Redcar::Clipboard and a Redcar::History.
    def initialize
      @windows = []
      @window_handlers = Hash.new {|h,k| h[k] = []}
      create_clipboard
      create_history
      @event_spewer = EventSpewer.new
      @task_queue   = TaskQueue.new
    end
    
    def events
      @event_spewer
    end
  
    # Immediately stop the gui event loop.
    # (You should probably be running QuitCommand instead.)    
    def quit
      @task_queue.stop
      Redcar.gui.stop
    end
    
    # All open windows
    #
    # @return [Array<Redcar::Window>]
    def windows
      @windows
    end

    # Create a new Application::Window, and the controller for it.
    def new_window
      s = Time.now
      new_window = Window.new
      windows << new_window
      notify_listeners(:new_window, new_window)
      attach_window_listeners(new_window)
      new_window.refresh_menu
      new_window.show
      set_focussed_window(new_window)
      #puts "App#new_window took #{Time.now - s}s"
      new_window
    end   
    
    def make_sure_at_least_one_window_open
      if windows.length == 0
        new_window
      end
    end 
    
    # Removes a window from this Application. Should not be called by plugins,
    # use Window#close instead.
    def window_closed(window)
      windows.delete(window)
      if focussed_window == window
        self.focussed_window = windows.first
      end
      @window_handlers[window].each {|h| window.remove_listener(h) }
      
      @window_handlers.delete(window)
    end
    
    def self.storage
      @storage ||= begin
         storage = Plugin::Storage.new('application_plugin')
         storage.set_default('stay_resident_after_last_window_closed', false)
         storage
      end
    end
    
    # All Redcar::Notebooks in all Windows.
    def all_notebooks
      windows.inject([]) { |arr, window| arr << window.notebooks }.flatten
    end
    
    # All Redcar::Tabs in all Notebooks in all Windows.
    def all_tabs
      all_notebooks.inject([]) { |arr, notebook| arr << notebook.tabs }.flatten
    end
    
    # The focussed Redcar::Notebook in the focussed window, or nil.
    def focussed_window_notebook
      focussed_window.focussed_notebook if focussed_window
    end
    
    # The focussed Redcar::Tab in the focussed notebook in the focussed window.
    def focussed_notebook_tab
      focussed_window_notebook.focussed_tab if focussed_window_notebook
    end

    # The focussed Redcar::Window.    
    def focussed_window
      @focussed_window
    end
    
    # Set which window the app thinks is focussed. 
    # Should not be called by plugins, use Window#focus instead.
    def focussed_window=(window)
      set_focussed_window(window)
      notify_listeners(:focussed_window, window)
    end
    
    # Set which window the app thinks is focussed.
    # Should not be called by plugins, use Window#focus instead.
    def set_focussed_window(window)
      @focussed_window = window
    end
    
    # Redraw the main menu, reloading all the Menus and Keymaps from the plugins.
    def refresh_menu!
      @main_menu = nil
      @main_keymap = nil
      windows.each {|window| window.refresh_menu }
      controller.refresh_menu
    end
    
    # Generate the main menu by combining menus from all plugins.
    #
    # @return [Redcar::Menu]
    def main_menu
      @main_menu ||= begin
        menu = Menu.new
        Redcar.plugin_manager.objects_implementing(:menus).each do |object|
          menu.merge(object.menus)
        end
        menu
      end
    end
    
    # Generate the main keymap by merging the keymaps from all plugins.
    #
    # @return [Redcar::Keymap]
    def main_keymap
      @main_keymap ||= begin
        keymap = Keymap.new("main", Redcar.platform)
        Redcar.plugin_manager.objects_implementing(:keymaps).each do |object|
          maps = object.keymaps
          keymaps = maps.select do |map| 
            map.name == "main" and map.platforms.include?(Redcar.platform)
          end
          keymap = keymaps.inject(keymap) {|k, nk| k.merge(nk) }
        end
        keymap
      end
    end
    
    # Loads sensitivities from all plugins.
    def load_sensitivities
      Redcar.plugin_manager.objects_implementing(:sensitivities).each do |object|
        object.sensitivities
      end
    end
    
    # Called by the Gui to tell the Application that it
    # has lost focus.
    def lost_application_focus
      return if @protect_application_focus
      @application_focus = false
      notify_listeners(:lost_focus, self)
    end
    
    # Called by the Gui to tell the Application that it
    # has gained focus.
    def gained_application_focus
      if @application_focus == false
        @application_focus = true
        notify_listeners(:focussed, self)
      end
    end
    
    def has_focus?
      @application_focus
    end
    
    def protect_application_focus
      @protect_application_focus = true
      r = yield
      @protect_application_focus = false
      r
    end
    
    private
    
    def attach_window_listeners(window)
      h1 = window.add_listener(:tab_focussed) do |tab|
        notify_listeners(:tab_focussed, tab)
      end
      h2 = window.add_listener(:closed) do |win|
        window_closed(win)
      end
      h3 = window.add_listener(:focussed) do |win|
        self.focussed_window = win
        notify_listeners(:window_focussed, win)
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
      h10 = window.add_listener(:about_to_close) do |win|
        notify_listeners(:window_about_to_close, win)
      end
      @window_handlers[window] << h1 << h2 << h3 << h4 << h5 << h6 << h7 << h8 << h9 << h10
    end
    
    def create_clipboard
      @clipboard       = Clipboard.new("application")
      @clipboard.add_listener(:added) { notify_listeners(:clipboard_added) }
    end
    
    def create_history
      @history = Command::History.new
    end
  end
end






