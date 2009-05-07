
module Redcar
  class SaveTabAs < Redcar::EditTabCommand
    key "Ctrl+Shift+S"
    icon :SAVE_AS

    def initialize(filename=nil)
      @filename = filename
    end

    def do_save
      tab.detect_and_set_grammar
      tab.save
    end

    def execute
      if @filename
        tab.filename = @filename
        do_save
      else
        Redcar::Dialog.save_as(win) do |filename|
          @filename = filename
          if File.exist?(@filename) and @filename != tab.filename
            unless Zerenity::Question(:text => "File #{@filename} already exists. Overwrite?")
              return
            end
            do_save
          end
        end
      end
    end
  end
end
