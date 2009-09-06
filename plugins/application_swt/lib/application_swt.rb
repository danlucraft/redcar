
module Redcar
  class ApplicationSWT < Plugin
    class << self
      attr_accessor :gui
    end
    
    def self.on_load
      @gui = Redcar::Gui.new("swt")
      @gui.register_event_loop(ApplicationSWT::EventLoop)
    end
  end
end

require "application_swt/event_loop"
