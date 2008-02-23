
module Redcar
  module App
    extend FreeBASE::StandardPlugin

    def self.quit
      bus["/system/shutdown"].call(nil)
      Gtk.main_quit
    end
    
    def self.new_window(focus = true)
      return nil if @window
      @window = Redcar::Window.new
    end
    
    def self.windows
      if @window
        [@window]
      end
    end
    
    def self.focussed_window
      @window
    end
    
    def self.close_window(window, close_if_no_win=true)
      is_win = windows
      @window = nil if window == @window
      # TODO close window logic - remove tabs etc.
      quit if close_if_no_win and is_win
    end
    
    def self.close_all_windows(close_if_no_win=true)
      is_win = windows
      close_window(@window)
      quit if close_if_no_win and is_win
    end
  end
end

