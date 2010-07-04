
SWT_APP_NAME = "Redcar"

require "application_swt/swt_wrapper"
require "application_swt/swt/listener_helpers"
require "application_swt/tab"

require "application_swt/clipboard"
require "application_swt/cucumber_runner"
require "application_swt/dialog_adapter"
require "application_swt/dialogs/no_buttons_dialog"
require "application_swt/dialogs/filter_list_dialog_controller"
require "application_swt/event_loop"
require "application_swt/html_tab"
require "application_swt/menu"
require "application_swt/menu/binding_translator"
require "application_swt/notebook"
require "application_swt/notebook/tab_transfer"
require "application_swt/notebook/tab_drag_and_drop_listener"
require "application_swt/speedbar"
require "application_swt/treebook"
require "application_swt/window"
require "application_swt/swt/grid_data"

require "dist/application_swt"

module Redcar
  class ApplicationSWT
    include Redcar::Controller
    
    def self.display
      @display ||= Swt.display 
    end

    def self.start
      Swt::Widgets::Display.app_name = Redcar::Application::NAME
      @gui = Redcar::Gui.new("swt")
      @gui.register_event_loop(EventLoop.new)
      @gui.register_features_runner(CucumberRunner.new)
      @gui.register_controllers(
          Redcar::Tab              => ApplicationSWT::Tab,
          Redcar::HtmlTab          => ApplicationSWT::HtmlTab,
          Redcar::FilterListDialog => ApplicationSWT::FilterListDialogController
        )
      @gui.register_dialog_adapter(ApplicationSWT::DialogAdapter.new)
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
      @gui
    end
    
    # Runs the given block in the SWT Event thread
    def self.sync_exec(&block)
      runnable = Swt::RRunnable.new do
        begin
          block.call
        rescue => e
          puts "error in sync exec"
          puts e.message
          puts e.backtrace
        end
      end
      Redcar::ApplicationSWT.display.syncExec(runnable)
    end
    
    # Runs the given block in the SWT Event thread after
    # the given number of milliseconds
    def self.timer_exec(ms, &block)
      runnable = Swt::RRunnable.new(&block)
      Redcar::ApplicationSWT.display.timerExec(ms, runnable)
    end

    class ShellListener
      def shell_deactivated(_)
        ApplicationSWT.timer_exec(100) do
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
      if Redcar.platform == :osx
        @fake_shell = Swt::Widgets::Shell.new(ApplicationSWT.display, Swt::SWT::NO_TRIM)
        @fake_shell.open
        @fake_shell.set_size(0, 0)
      end
    end
      
    class FakeWindow
      def initialize(shell)
        @shell = shell
      end
      
      attr_reader :shell
    end

    def refresh_menu
      if Redcar.platform == :osx
        old_menu_bar = @fake_shell.menu_bar
        fake_menu_controller = ApplicationSWT::Menu.new(FakeWindow.new(@fake_shell), Redcar.app.main_menu, Redcar.app.main_keymap, Swt::SWT::BAR)
        fake_shell.menu_bar = fake_menu_controller.menu_bar
        old_menu_bar.dispose if old_menu_bar
      end
    end

    def add_listeners
      @model.add_listener(:new_window, &method(:new_window))
    end
    
    class Listener
      def initialize(name)
        @name = name
      end
      
      def handle_event(e)
        Application::Dialog.message_box("#{@name} menu is not hooked up yet")
      end
    end
    
    class QuitListener
      def handle_event(e)
        unless Redcar.app.events.ignore?(:application_close, Redcar.app)
          e.doit = false
          Redcar.app.events.create(:application_close, Redcar.app)
        end
      end
    end
    
    def add_swt_listeners
      if Redcar.platform == :osx
        quit_listener  = Listener.new(:quit)
        about_listener = Listener.new(:about)
        prefs_listener = Listener.new(:prefs)
        enhancer = com.redcareditor.application_swt.CocoaUIEnhancer.new("Redcar")
        enhancer.hook_application_menu(
          ApplicationSWT.display,
          QuitListener.new, 
          about_listener, 
          prefs_listener
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
