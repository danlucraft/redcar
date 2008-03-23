
module Redcar
  # Application wide configuration. App manages Redcar::Windows (of which
  # there may only be one currently).
  module App
    extend FreeBASE::StandardPlugin

    def self.load(plugin) # :nodoc:
      Hook.register :open_window
      Hook.register :close_window
      plugin.transition(FreeBASE::LOADED)
    end
    
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
      Hook.trigger :open_window do
        @window = Redcar::Window.new
      end
    end
    
    # Returns an array of all Redcar windows.
    def self.windows
      [@window]
    end
    
    # Returns the currently focussed window.
    def self.focussed_window
      @window
    end
    
    # Closes the given window. If close_if_no_win is true (the default)
    # then Redcar will quit if there are no more windows.
    def self.close_window(window, close_if_no_win=true)
      is_win = !windows.empty?
      if window
        Hook.trigger :close_window do
          window.panes.each {|pane| pane.tabs.each {|tab| tab.close} }
          Keymap.clear_keymaps_from_object(window)
          @window = nil if window == @window
          window.hide_all if window
        end
      end
      quit if close_if_no_win and is_win
    end
    
    # Closes all Redcar windows. If close_if_no_win is true (the 
    # default) then Redcar will quit.
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
