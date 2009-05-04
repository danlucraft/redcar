
module Redcar
  class SaveTabAs < Redcar::EditTabCommand
    key "Ctrl+Shift+S"
    icon :SAVE_AS

    def initialize(filename=nil)
      @filename = filename
    end

    def execute
      unless @filename
        @filename ||= Redcar::Dialog.save_as(win)
        if File.exist?(@filename) and @filename != tab.filename
          unless Zerenity::Question(:text => "File #{@filename} already exists. Overwrite?")
            return
          end
        end
      end
      tab.filename = @filename
      tab.detect_and_set_grammar
      tab.save
    end
  end
end
