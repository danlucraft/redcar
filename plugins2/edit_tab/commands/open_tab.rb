module Redcar
  class OpenTab < Redcar::Command
    key "Ctrl+O"
    icon :NEW

    def initialize(filename=nil)
      @filename = filename
    end

    def execute
      if !@filename
        @filename = Redcar::Dialog.open(win)
      end
      if @filename and File.file?(@filename)
        new_tab = win.new_tab(Redcar::EditTab)
        new_tab.load(@filename)
        new_tab.focus
      else
        puts "no file: #{@filename}"
      end
    end
  end
end
