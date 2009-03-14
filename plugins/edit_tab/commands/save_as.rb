
module Redcar
  class SaveTabAs < Redcar::EditTabCommand
    key "Ctrl+Shift+S"
    icon :SAVE

    def execute
      if filename = Redcar::Dialog.save
        tab.filename = filename
        tab.detect_and_set_grammar
        tab.save
      end
    end
  end
end
