
module Redcar
  class PreviousLineCommand < Redcar::EditTabCommand
    key "Ctrl+P"
    
    def execute
      tab.view.signal_emit("move-cursor", Gtk::MOVEMENT_DISPLAY_LINES, -1, false)
    end
  end
end
