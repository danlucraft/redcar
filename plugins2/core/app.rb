
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

# Some useful methods for finding the currently focussed objects.
class Object
  # The current or last focussed Document.
  def doc
    tab.document
  end
  
  # The current or last focussed Tab
  def tab
    win.focussed_tab
  end
  
  # The current or last focussed Window
  def win
    Redcar::App.focussed_window
  end
end
