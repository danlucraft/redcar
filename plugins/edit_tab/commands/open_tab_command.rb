module Redcar
  class OpenTabCommand < Redcar::Command
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
      if tab = EditTab.find_tab_for_file(@filename)
        tab.focus
        tab
      elsif @filename and File.file?(@filename)
        new_tab = (@pane||win).new_tab(Redcar::EditTab)
        new_tab.load(@filename)
        new_tab.focus
        new_tab
      else
        puts "no file: #{@filename}"
      end
    end
  end
end
