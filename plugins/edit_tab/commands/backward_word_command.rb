module Redcar
  class BackwardWordCommand < Redcar::EditTabCommand
    key  "Alt+B"
    icon :GO_BACK

    def execute
      tab.view.signal_emit("move-cursor", Gtk::MOVEMENT_WORDS, -1, false)
    end
  end

end
