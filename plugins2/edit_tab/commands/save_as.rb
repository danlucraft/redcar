
module Redcar
  class SaveTabAs < Redcar::EditTabCommand
    key "Ctrl+Shift+S"
    icon :SAVE

    def execute
      filename = Redcar::Dialog.save
      tab.filename = filename
      tab.save
    end
  end
end
