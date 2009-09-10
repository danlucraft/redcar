
require "application_swt/event_loop"
require "application_swt/swt_wrapper"

module Redcar
  class ApplicationSWT
    def self.display
      @display ||= Swt::Widgets::Display.new
    end
    
    def self.load
      Swt::Widgets::Display.app_name = Redcar::Application::NAME
      gui = Redcar::Gui.new("swt")
      gui.register_event_loop(ApplicationSWT::EventLoop.new)
      Application.gui = gui
    end
  end
end
