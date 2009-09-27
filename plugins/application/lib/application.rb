
require 'application/window'
require 'application/menu'
require 'application/menu_item'

module Redcar
  class << self
    attr_reader :gui, :app
  end

  def self.app=(app)
    @app ||= app
  end
  
  # Set the application GUI.
  def self.gui=(gui)
    raise "can't set gui twice" if @gui
    @gui = gui
    
    bus["/system/ui/messagepump"].set_proc do
      @gui.controller_for(@app)
      @gui.start
    end
  end
  
  class Application
    NAME = "Redcar"
    
    include Redcar::Model
    include FreeBASE::DataBusHelper
    
    def self.load
      
    end
    
    def self.start
      Redcar.app = Application.new
      Redcar.app.new_window
    end
    
    def initialize
    end
    
    # Immediately halts the gui event loop.
    def quit
      Redcar.gui.stop
    end
    
    # Return a list of all open windows
    def windows
      @windows ||= []
    end

    # Create a new Application::Window, and the controller for it.
    def new_window
      new_window = Application::Window.new
      windows << new_window
      Redcar.gui.controller_for(new_window)
      # menu = Menu.new
      # menu << Menu.new("File") 
      # menu << Menu.new("Help")
      new_window.show
    end
    
    # The main menu.
    def menu=(menu)
      @menu = menu
      controller.menu_changed
    end
    
  end
end