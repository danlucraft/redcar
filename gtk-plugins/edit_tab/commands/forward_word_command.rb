module Redcar
  class ForwardWordCommand < Redcar::EditTabCommand
    key  "Alt+F"
    icon :GO_FORWARD
    
    def execute
      tab.view.signal_emit("move-cursor", Gtk::MOVEMENT_WORDS, +1, false)
    end
  end
end

