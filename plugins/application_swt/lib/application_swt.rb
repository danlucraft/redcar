
require "application_swt/event_loop"
require "application_swt/swt_wrapper"
require "application_swt/window"
require "application_swt/cucumber_runner"
require "application_swt/menu"

module Redcar
  class ApplicationSWT
    include Redcar::Controller
    
    def self.display
      @display ||= Swt::Widgets::Display.new
    end
    
    def self.load
    end
    
    def self.start
      Swt::Widgets::Display.app_name = Redcar::Application::NAME
      @gui = Redcar::Gui.new("swt")
      @gui.register_controller(controller_map)
      @gui.register_event_loop(EventLoop.new)
      @gui.register_features_runner(CucumberRunner.new)
      Redcar.gui = Redcar::ApplicationSWT.gui
    end
    
    def self.gui
      @gui
    end
    
    def self.controller_map
      { Application         => ApplicationSWT, 
        Application::Window => ApplicationSWT::Window,
        Redcar::Application::Menu => ApplicationSWT::Menu
      }
    end
    
    def menu_changed
      p :menu_changed
      Menu.new(self, @model.menu)
    end
  end
end
