
module Redcar
  class SaveTab < Redcar::EditTabCommand
    key "Ctrl+S"
    icon :SAVE
    sensitive :modified?

    def execute
      tab.save
    end
  end
end
