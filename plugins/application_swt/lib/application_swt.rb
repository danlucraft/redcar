
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
require "application_swt/notebook/drag_and_drop_listener"
require "application_swt/speedbar"
require "application_swt/treebook"
require "application_swt/window"
require "application_swt/swt/grid_data"

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
    
    #
    # allow other threads to run code "back in the GUI"
    #  
    def self.sync_exec(&block)
      runnable = Swt::RRunnable.new(&block)
      Redcar::ApplicationSWT.display.syncExec(runnable)
    end
    
    class ShellListener
      def shell_deactivated(_)
        unless Swt::Widgets::Display.get_current.get_active_shell
          Redcar.app.lost_application_focus
        end
      end
      
      def shell_activated(_)
        Redcar.app.gained_application_focus
      end
      
      def shell_closed(_); end
      def shell_deiconified(_); end
      def shell_iconified(_); end
    end

    # ALL new shells must be registered here, otherwise Redcar will
    # get confused about when it has lost the application focus.
    def self.register_shell(shell)
      shell.add_shell_listener(ShellListener.new)
    end
    
    def initialize(model)
      @model = model
      add_listeners
      create_clipboard
    end
    
    def add_listeners
      @model.add_listener(:new_window, &method(:new_window))
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
