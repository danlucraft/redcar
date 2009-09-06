
require "swt/event_loop"

module Redcar
  class SWT < Plugin
    class << self
      attr_accessor :gui
    end
    
    def self.on_load
      @gui = Redcar::Gui.new("swt")
      @gui.register_event_loop(SWT::EventLoop)
    end
  end
end