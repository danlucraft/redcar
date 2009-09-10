
module Redcar
  class ApplicationSWT
    class << self
      def display
        @display ||= Swt::Widgets::Display.new
      end
    end
    
    def self.load
      Swt::Widgets::Display.app_name = "Redcar"
      gui = Redcar::Gui.new("swt")
      gui.register_event_loop(ApplicationSWT::EventLoop.new)
      Application.gui = gui
    end
  end
end

require "application_swt/event_loop"
require "application_swt/swt_wrapper"
