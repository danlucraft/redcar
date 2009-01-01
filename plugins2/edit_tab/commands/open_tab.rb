module Redcar
  class OpenTab < Redcar::Command
    key "Ctrl+O"
    icon :NEW

    def initialize(filename=nil, pane=nil)
      @filename = filename
      @pane = pane
    end

    def execute
      if !@filename
        @filename = Redcar::Dialog.open(win)
      end
      if @filename and File.file?(@filename)
        p win
        new_tab = (@pane||win).new_tab(Redcar::EditTab)
        new_tab.load(@filename)
        new_tab.focus
      else
        puts "no file: #{@filename}"
      end
    end
  end
end
