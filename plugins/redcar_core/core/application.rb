
module Redcar
  # Closes the entire Redcar application, after 
  # calling the Redcar event :quit
  def self.quit
    Redcar.event :quit
    Redcar.event :shutdown
    Gtk.main_quit
  end
  
  class << self
    attr_accessor :windows, :panes, :edit_pane, :window_controller, :output_style
  end
  
  # False if redcar echoes events to STDOUT, true if it is silent.
  def self.silent?
    output_style == :silent
  end
  
end
