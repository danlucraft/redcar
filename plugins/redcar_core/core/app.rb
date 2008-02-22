
module Redcar
  module App
    
    # API methods
    
    def self.quit
      Redcar.event :quit
      Redcar.event :shutdown
      $BUS["/system/shutdown"].call(nil)
      Gtk.main_quit
    end
    
    def self.bus
      
    end
    
    # Makes a new window. Currently only one window is allowed.
    def self.new_window(focus = true)
      return nil if @window
      @window = Redcar::Window.new
    end
    
    def self.windows
      [@window]
    end
    
    def self.focussed_window
      @window
    end
    
    def self.close_all_windows
      @window.close
      quit
    end
    
    # -----

    class << self
      attr_accessor :output_style
    end
    
    def self.close_window(win)
      win.hide_all
     # TODO close window logic - remove tabs etc.
      quit
    end
    
    def self.silent?
      output_style == :silent
    end
  end
end
