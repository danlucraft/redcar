
require 'application/command/executor'
require 'application/command/history'
require 'application/sensitive'
require 'application/sensitivity'
require 'application/command'
require 'application/dialog'
require 'application/menu'
require 'application/menu/item'
require 'application/menu/builder'
require 'application/notebook'
require 'application/tab'
require 'application/tab/command'
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
  end
  
  class Application
    NAME = "Redcar"
    
    include Redcar::Model
    include Redcar::Observable
    
    def self.load
      Redcar.freebase_core.bus["/system/ui/messagepump"].set_proc do
        Redcar.gui.start
      end
    end
    
    def self.start
      Redcar.app     = Application.new
      Redcar.history = Command::History.new
      Sensitivity.new(:open_tab, Redcar.app, false, [:tab_focussed]) do |tab|
        tab
      end
    end
    
    def initialize
      @windows = []
      @window_handlers = Hash.new {|h,k| h[k] = []}
    end
    
    # Immediately halts the gui event loop.
    def quit
      Redcar.gui.stop
    end
    
    # Return a list of all open windows
    def windows
      @windows
    end

    # Create a new Application::Window, and the controller for it.
    def new_window
      new_window = Window.new
      windows << new_window
      notify_listeners(:new_window, new_window)
      attach_window_listeners(new_window)
      new_window.menu = menu
      new_window.show
      set_focussed_window(new_window)
      new_window
    end
    
    # Removes a window from this Application. Should not be called by user
    # code, use Window#close instead.
    def window_closed(window)
      windows.delete(window)
      @window_handlers[window].each {|h| window.remove_listener(h) }
      @window_handlers.delete(window)
    end
    
    def focussed_window
      @focussed_window
    end
    
    def focussed_window=(window)
      set_focussed_window(window)
      notify_listeners(:focussed_window, window)
    end
    
    def set_focussed_window(window)
      p [:focussed_window, window]
      @focussed_window = window
    end
    
    attr_reader :menu
    
    # The main menu.
    def menu=(menu)
      @menu = menu
      windows.each do |window|
        window.menu = menu
      end
    end
    
    def attach_window_listeners(window)
      h1 = window.add_listener(:tab_focussed) do |tab|
        notify_listeners(:tab_focussed, tab)
      end
      h2 = window.add_listener(:closed) do |win|
        window_closed(win)
      end
      @window_handlers[window] << h1 << h2
    end
  end
end






