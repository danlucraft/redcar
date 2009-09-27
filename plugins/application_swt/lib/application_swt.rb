
require "application_swt/event_loop"
require "application_swt/swt_wrapper"
require "application_swt/window"
require "application_swt/cucumber_runner"

module Redcar
  class ApplicationSWT
    include Redcar::Controller
    
    def self.display
      @display ||= Swt::Widgets::Display.new
    end
    
    def self.load
      Swt::Widgets::Display.app_name = Redcar::Application::NAME
      gui = Redcar::Gui.new("swt")
      gui.register_controller(Application => ApplicationSWT)
      gui.register_event_loop(EventLoop.new)
      gui.register_controller(Application::Window => Window)
      gui.register_features_runner(CucumberRunner.new)
      Redcar.gui = gui
    end
  end
end
