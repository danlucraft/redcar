
require 'application/command/executor'
require 'application/command/history'
require 'application/command/sensitive'
require 'application/command/sensitivity'
require 'application/command'
require 'application/dialog'
require 'application/menu'
require 'application/menu/item'
require 'application/menu/builder'
require 'application/notebook'
require 'application/tab'
require 'application/window'

module Redcar
  class << self
    attr_accessor :app, :history
    attr_reader :gui
  end

  # Set the application GUI.
  def self.gui=(gui)
    raise "can't set gui twice" if @gui
    @gui = gui
    
    bus["/system/ui/messagepump"].set_proc do
      @gui.start
    end
  end
  
  class Application
    NAME = "Redcar"
    
    include Redcar::Model
    include Redcar::Observable
    
    def self.load
    end
    
    def self.start
      Redcar.app     = Application.new
      Redcar.history = Command::History.new
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
      new_window = Window.new
      windows << new_window
      notify_listeners(:new_window, new_window)
      new_window.menu = menu
      new_window.show
    end
    
    attr_reader :menu
    
    # The main menu.
    def menu=(menu)
      @menu = menu
      windows.each do |window|
        window.menu = menu
      end
    end
  end
end

