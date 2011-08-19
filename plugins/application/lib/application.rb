
require 'yaml'

require 'application/command/executor'
require 'application/command/history'
require 'application/sensitive'
require 'application/sensitivity'
require 'application/clipboard'
require 'application/command'

require 'application/dialog'
require 'application/dialogs/filter_list_dialog'
require 'application/dialogs/modeless_list_dialog'
require 'application/event_spewer'
require 'application/keymap'
require 'application/keymap/builder'
require 'application/toolbar'
require 'application/toolbar/item'
require 'application/toolbar/lazy_toolbar'
require 'application/toolbar/builder'
require 'application/toolbar/builder/group'
require 'application/menu'
require 'application/menu/item'
require 'application/menu/lazy_menu'
require 'application/menu/builder'
require 'application/menu/builder/group'
require 'application/navigation_history'
require 'application/notebook'
require 'application/speedbar'
require 'application/tab'
require 'application/tab/command'
require 'application/tree'
require 'application/tree/command'
require 'application/tree/controller'
require 'application/tree/mirror'
require 'application/treebook'
require 'application/window'

require 'application/commands/application_commands'
require 'application/commands/tab_commands'
require 'application/commands/notebook_commands'
require 'application/commands/window_commands'
require 'application/commands/treebook_commands'

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
      Redcar.plugin_manager.objects_implementing(:app_started).each do |object|
        object.app_started
      end
    end

    def self.sensitivities
      [
        Sensitivity.new(:open_tab, Redcar.app, false, [:focussed_window, :tab_focussed]) do |tab|
          if win = Redcar.app.focussed_window
            win.focussed_notebook.focussed_tab
          end
        end,
        Sensitivity.new(:open_htmltab, Redcar.app, false, [:focussed_window, :tab_focussed]) do |tab|
          if win = Redcar.app.focussed_window and
            tab = win.focussed_notebook.focussed_tab
            tab.is_a?(HtmlTab)
          end
        end,
        Sensitivity.new(:open_trees, Redcar.app, false, [:focussed_window, :tree_added, :tree_removed]) do |tree|
          if win = Redcar.app.focussed_window
            trees = win.treebook.trees
            trees and trees.length > 0
          end
        end,
        Sensitivity.new(:focussed_committed_mirror, Redcar.app, false,
          [:focussed_window, :notebook_change, :mirror_committed, :tab_focussed]) do
          if win = Redcar.app.focussed_window and tab = win.focussed_notebook.focussed_tab
            begin;tab.edit_view.document.mirror.path;rescue;false;end
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
        end,
        Sensitivity.new(:always_disabled, Redcar.app, false,[]) do; false; end
      ]
    end

    attr_reader :clipboard, :keymap, :menu, :toolbar, :history, :task_queue, :show_toolbar, :navigation_history

    # Create an application instance with a Redcar::Clipboard and a Redcar::History.
    def initialize
      @windows = []
      @window_handlers = Hash.new {|h,k| h[k] = []}
      create_clipboard
      create_history
      @navigation_history = NavigationHistory.new
      @event_spewer = EventSpewer.new
      @task_queue   = TaskQueue.new
      @show_toolbar = !!Application.storage['show_toolbar']
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
    def new_window(show=true)
      s = Time.now
      new_window = Window.new
      windows << new_window
      notify_listeners(:new_window, new_window)
      attach_window_listeners(new_window)
      new_window.refresh_menu
      new_window.refresh_toolbar
      show_window(new_window) if show
      new_window
    end

    def show_window(window)
      window.show
      set_focussed_window(window)
    end

    def make_sure_at_least_one_window_open
      if windows.length == 0
        new_window
      end
    end

    def make_sure_at_least_one_window_there
      if windows.length == 0
        win = new_window(false)
        set_focussed_window(win)
        win
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
        storage.set_default('show_toolbar', true)
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
      notify_listeners(:refresh_menu)
    end

    # Redraw the main toolbar, reloading all the ToolBars and Keymaps from the plugins.
    def refresh_toolbar!
      @main_toolbar = nil
      windows.each {|window| window.refresh_toolbar }
      controller.refresh_toolbar
    end
    
    # For every plugin that implements it, call the method with the given
    # arguments and pass the result to the block.
    #
    # @param [Symbol] method_name
    def call_on_plugins(method_name, *args)
      Redcar.plugin_manager.objects_implementing(method_name).each do |object|
        result = object.send(method_name, *args)
        yield result if block_given?
      end
      nil
    end

    # Generate the main menu by combining menus from all plugins.
    #
    # @return [Redcar::Menu]
    def main_menu(window=nil)
      @main_menu ||= begin
        menu = Menu.new
        Redcar.plugin_manager.objects_implementing(:menus).each do |object|
          case object.method(:menus).arity
          when 1
            menu.merge(object.menus(window))
          else
            menu.merge(object.menus)
          end
        end
        menu
      end
    end

    # Generate the toolbar combining toolbars from all plugins.
    #
    # @return [Redcar::ToolBar]
    def main_toolbar
      @main_toolbar ||= begin
        toolbar = ToolBar.new
        Redcar.plugin_manager.objects_implementing(:toolbars).each do |object|
          toolbar.merge(object.toolbars)
        end
        toolbar
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
          unless maps
            Redcar.log.warn("#{object.inspect} implements :keymaps but :keymaps returns nil")
            maps = []
          end
          keymaps = maps.select do |map|
            map.name == "main" and map.platforms.include?(Redcar.platform)
          end
          keymap = keymaps.inject(keymap) {|k, nk| k.merge(nk) }
        end
        apply_user_keybindings(keymap)
      end
    end

    def apply_user_keybindings(keymap)
      Redcar.plugin_manager.objects_implementing(:user_keybindings).each do |object|
        keymap.map.merge!(object.user_keybindings)
      end
      keymap
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

    def repeat_event(type)
      notify_listeners(type)
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

    public

    def show_toolbar?
      @show_toolbar
    end

    def show_toolbar=(bool)
      Application.storage['show_toobar'] = @show_toolbar = bool
    end

    def toggle_show_toolbar
      Application.storage['show_toolbar'] = @show_toolbar = !Application.storage['show_toolbar']
    end
  end
end
