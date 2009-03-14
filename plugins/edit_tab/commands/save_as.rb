
module Redcar
  class SaveTabAs < Redcar::EditTabCommand
    key "Ctrl+Shift+S"
    icon :SAVE

    def execute
      if filename = Redcar::Dialog.save
        if File.exist?(filename) and filename != tab.filename
          unless Zerenity::Question(:text => "File #{filename} already exists. Overwrite?")
            return
          end
        end
        tab.filename = filename
        tab.detect_and_set_grammar
        tab.save
      end
    end
  end
end
