
require 'application/window'
require 'application/menu'
require 'application/menu_item'

module Redcar
  def self.app
    @app ||= Application.new
  end
  
  class Application
    NAME = "Redcar"
    
    include FreeBASE::DataBusHelper
    
    def self.load
      
    end
    
    def self.start
      Redcar.app.new_window
    end
    
    # Immediately halts the gui event loop.
    def quit
      @gui.stop
    end
    
    # Return a list of all open windows
    def windows
      @windows ||= []
    end

    # Create a new Application::Window, and the controller for it.
    def new_window
      new_window = Application::Window.new
      windows << new_window
      @gui.controller_for(new_window).new(new_window)
    end
    
    # Set the application GUI.
    def gui=(gui)
      raise "can't set gui twice" if @gui
      @gui = gui
      
      bus["/system/ui/messagepump"].set_proc do
        @gui.start
      end
    end
    
    attr_reader :gui
  end
end