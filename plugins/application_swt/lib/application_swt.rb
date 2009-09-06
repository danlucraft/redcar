
module Redcar
  class ApplicationSWT < Plugin
    def self.on_load
      gui = Redcar::Gui.new("swt")
      gui.register_event_loop(ApplicationSWT::EventLoop)
      Application.gui = gui
    end
  end
end

require "application_swt/event_loop"
