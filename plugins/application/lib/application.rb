
module Redcar
  class Application
    NAME = "Redcar"
    class << self
      # Set the application GUI.
      def gui=(gui)
        raise "can't set gui twice" if @gui
        @gui = gui
      end
      
      attr_reader :gui
    end
  
    def self.load
      
    end
    
    def self.start
      gui.start
    end
  end
end