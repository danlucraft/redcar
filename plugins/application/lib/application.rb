
require 'application/window'

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
    
    def windows
      @windows ||= []
    end
    
    def new_window
      windows << Application::Window.new
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