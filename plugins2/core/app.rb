
module Redcar
  # Application wide configuration. App manages Redcar::Windows (of which
  # there may only be one currently).
  module App
    extend FreeBASE::StandardPlugin

    # The expanded absolute application directory.
    def self.root_path
      File.expand_path(File.dirname(__FILE__)+"/../..")
    end
    
    # Quits the application. All plugins are stopped first.
    def self.quit 
      unless @gtk_quit
        bus["/system/shutdown"].call(nil)
        Gtk.main_quit
      end
      @gtk_quit = true
    end
    
    # Creates a new window.
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
    
    def self.close_window(window, close_if_no_win=true)
      is_win = !windows.empty?
      @window = nil if window == @window
      window.hide_all if window
      quit if close_if_no_win and is_win
    end
    
    def self.close_all_windows(close_if_no_win=true)
      is_win = !windows.empty?
      close_window(@window, close_if_no_win)
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
