
module Redcar
  class Application < Plugin
    class << self
      def gui=(gui)
        raise "can't set gui twice" if @gui
        @gui = gui
      end
      
      attr_reader :gui
    end
  
    def self.on_load
      
    end
    
    def self.on_start
      gui.start
    end
  end
end