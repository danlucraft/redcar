
module Redcar
  class ForwardCharacterCommand < Redcar::EditTabCommand
    key "Ctrl+F"
    
    def execute
      tab.view.signal_emit("move-cursor", Gtk::MOVEMENT_VISUAL_POSITIONS, +1, false)
    end
  end
end
