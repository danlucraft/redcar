
require "application_swt/cucumber_runner"
require "application_swt/event_loop"
require "application_swt/menu"
require "application_swt/notebook"
require "application_swt/swt_wrapper"
require "application_swt/window"

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
    end
    
    def self.start
    end
    
    def self.gui
      @gui
    end
    
    def initialize(application)
      @application = application
    end
    
    def menu_changed
      Menu.new(self, @model.menu)
    end
  end
end
