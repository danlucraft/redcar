
module Redcar
  class SaveTab < Redcar::EditTabCommand
    key "Super+S"
    icon :SAVE
    sensitive :modified?

    def execute
      tab.save
    end
  end
end
