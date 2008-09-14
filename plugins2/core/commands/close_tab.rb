
module Redcar
  class CloseTab < Redcar::TabCommand
    key "Ctrl+W"
    icon :CLOSE

    def initialize(tab=nil)
      @tab = tab
    end

    def execute
      @tab ||= tab
      @tab.close if @tab
    end
  end
end
