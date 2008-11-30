
module Redcar
  class BackwardCharacterCommand < Redcar::EditTabCommand
    key "Ctrl+B"
    
    def execute
      tab.view.signal_emit("move-cursor", Gtk::MOVEMENT_VISUAL_POSITIONS, -1, false)
    end
  end
end
