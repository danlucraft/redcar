
module Redcar
  class NextLineCommand < Redcar::EditTabCommand
    key "Ctrl+N"
    
    def execute
      tab.view.signal_emit("move-cursor", Gtk::MOVEMENT_DISPLAY_LINES, +1, false)
    end
  end
end
