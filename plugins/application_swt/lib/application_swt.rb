
require 'swt/full'

require "application_swt/tab"

require "application_swt/clipboard"
require "application_swt/dialog_adapter"
require "application_swt/dialogs/no_buttons_dialog"
require "application_swt/dialogs/text_and_file_dialog"
require "application_swt/dialogs/filter_list_dialog_controller"
require "application_swt/dialogs/input_dialog"
require "application_swt/dialogs/modeless_dialog"
require "application_swt/dialogs/modeless_html_dialog"
require "application_swt/dialogs/modeless_list_dialog_controller"
require "application_swt/gradient"
require "application_swt/html_tab"
require "application_swt/icon"
require "application_swt/listener_helpers"
require "application_swt/menu"
require "application_swt/menu/binding_translator"
require "application_swt/toolbar"
require "application_swt/toolbar/binding_translator"
require "application_swt/notebook"
require "application_swt/notebook/tab_transfer"
require "application_swt/notebook/tab_drag_and_drop_listener"
require "application_swt/speedbar"
require "application_swt/treebook"
require "application_swt/window"

require "dist/application_swt"

module Redcar
  class ApplicationSWT
    include Redcar::Controller
    
    attr_reader :fake_shell

    def self.display
      @display ||= Swt.display
    end

    def self.start
      if Redcar.gui
        Redcar.gui.register_controllers(
            Redcar::Tab                => ApplicationSWT::Tab,
            Redcar::HtmlTab            => ApplicationSWT::HtmlTab,
            Redcar::FilterListDialog   => ApplicationSWT::FilterListDialogController,
            Redcar::ModelessListDialog => ApplicationSWT::ModelessListDialogController
          )
        Redcar.gui.register_dialog_adapter(ApplicationSWT::DialogAdapter.new)
      end
    end

    def self.selected_tab_background
      Gradient.new(Redcar::ApplicationSWT.storage['selected_tab_background'])
    end

    def self.unselected_tab_background
      Gradient.new(Redcar::ApplicationSWT.storage['unselected_tab_background'])
    end

    def self.tree_background
      Gradient.new(Redcar::ApplicationSWT.storage['tree_background'])
    end

    def self.storage
      @storage ||= begin
        storage = Plugin::Storage.new('application_swt')
        storage.set_default('selected_tab_background', {0 => "#FEFEFE", 100 => "#EEEEEE"})
        storage.set_default('unselected_tab_background', {0 => "#E5E5E5", 100 => "#D0D0D0"})
        storage.set_default('tree_background', "#FFFFFF")
        storage
      end
    end

    def self.add_debug_key_filters
      display.add_filter(Swt::SWT::KeyDown) do |a|
        puts "type: #{a.type}, keyCode: #{a.keyCode}, character: #{a.character}, statemask: #{a.stateMask}"
      end
      display.add_filter(Swt::SWT::KeyUp) do |a|
        puts "type: #{a.type}, keyCode: #{a.keyCode}, character: #{a.character}, statemask: #{a.stateMask}"
      end
    end

    def self.gui
      Redcar.gui
    end

    class ShellListener
      def shell_deactivated(_)
        Swt.timer_exec(100) do
          unless Swt::Widgets::Display.get_current.get_active_shell
            Redcar.app.lost_application_focus
          end
        end
      end

      def shell_activated(_)
        Redcar.app.gained_application_focus
      end

      def shell_closed(_);      end
      def shell_deiconified(_); end
      def shell_iconified(_);   end
    end

    # ALL new shells must be registered here, otherwise Redcar will
    # get confused about when it has lost the application focus.
    def self.register_shell(shell)
      shell.add_shell_listener(ShellListener.new)
    end

    def self.shell_dialogs
      @shell_dialogs ||= {}
    end

    def self.register_dialog(shell, dialog)
      shell_dialogs[shell] = dialog
    end

    def self.unregister_dialog(dialog)
      shell_dialogs.delete(shell_dialogs.invert[dialog])
    end

    def initialize(model)
      @model = model
      add_listeners
      add_swt_listeners
      create_clipboard
      create_fake_window
    end

    def fake_shell
      @fake_shell
    end

    def create_fake_window
      @fake_shell = Swt::Widgets::Shell.new(ApplicationSWT.display, Swt::SWT::NO_TRIM)
      @fake_shell.open
      @fake_shell.set_size(0, 0)
      @fake_shell.set_visible(false) unless Redcar.platform == :osx
    end

    class FakeWindow
      def initialize(shell)
        @shell = shell
      end

      attr_reader :shell
    end

    def refresh_menu
      if Redcar.platform == :osx and @fake_shell
        old_menu_bar = @fake_shell.menu_bar
        fake_menu_controller = ApplicationSWT::Menu.new(FakeWindow.new(@fake_shell), Redcar.app.main_menu, Redcar.app.main_keymap, Swt::SWT::BAR)
        fake_shell.menu_bar = fake_menu_controller.menu_bar
        old_menu_bar.dispose if old_menu_bar
      end
    end

    def refresh_toolbar
      # if Redcar.platform == :osx and @fake_shell
      #   fake_toolbar_controller = ApplicationSWT::ToolBar.new(FakeWindow.new(@fake_shell), Redcar.app.main_toolbar, Swt::SWT::FLAT)
      # end
    end

    def add_listeners
      @model.add_listener(:new_window, &method(:new_window))
      @model.add_listener(:refresh_menu, &method(:refresh_menu))
    end

    class CocoaUIListener

      def initialize(name)
        @name = name
      end

      def handle_event(e)
        if    @name == :prefs
          Redcar::PluginManagerUi::OpenPreferencesCommand.new.run
        elsif @name == :about
          Redcar::Top::AboutCommand.new.run
        elsif @name == :quit
          unless Redcar.app.events.ignore?(:application_close, Redcar.app)
            e.doit = false
            Redcar.app.events.create(:application_close, Redcar.app)
          end
        else
          Application::Dialog.message_box("#{@name} menu is not hooked up yet")
        end
      end
    end

    def add_swt_listeners
      if Redcar.platform == :osx
        enhancer = com.redcareditor.application_swt.CocoaUIEnhancer.new("Redcar")
        enhancer.hook_application_menu(
          ApplicationSWT.display,
          CocoaUIListener.new(:quit),
          CocoaUIListener.new(:about),
          CocoaUIListener.new(:prefs)
        )
      end
    end

    def create_clipboard
      ApplicationSWT::Clipboard.new(@model.clipboard)
    end

    def new_window(win)
      win.controller = ApplicationSWT::Window.new(win)
    end

    def menu_changed
      Menu.new(self, @model.menu)
    end
  end
end
