
require "application_swt/cucumber_runner"
require "application_swt/dialog_adapter"
require "application_swt/event_loop"
require "application_swt/menu"
require "application_swt/menu/binding_translator"
require "application_swt/notebook"
require "application_swt/swt_wrapper"
require "application_swt/tab"
require "application_swt/window"
require "application_swt/shell_listener.rb"

module Redcar
  class ApplicationSWT
    include Redcar::Controller
    
    def self.display
      @display ||= Swt::Widgets::Display.new
    end
    
    def self.load
      Swt::Widgets::Display.app_name = Redcar::Application::NAME
      @gui = Redcar::Gui.new("swt")
      @gui.register_event_loop(EventLoop.new)
      @gui.register_features_runner(CucumberRunner.new)
      @gui.register_controllers(Redcar::Tab => ApplicationSWT::Tab)
      @gui.register_dialog_adapter(ApplicationSWT::DialogAdapter.new)
    end
    
    def self.start
      # add_debug_key_filters
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
    
    def self.sync_exec(&block)
      runnable = Swt::RRunnable.new(&block)
      Redcar::ApplicationSWT.display.syncExec(runnable)
    end
    
    def initialize(app)
      @app = app
      add_listeners
    end
    
    def add_listeners
      @app.add_listener(:new_window, &method(:new_window))
    end
    
    def new_window(win)
      win.controller = ApplicationSWT::Window.new(win)
    end
    
    def menu_changed
      Menu.new(self, @model.menu)
    end
  end
end
