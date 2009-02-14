module Redcar
  class ShiftTabPressed < Redcar::EditTabCommand
    key "Shift+Tab"

    def initialize(si=nil, buf=nil)
      @si = si
      @buf = buf
    end

    def execute
      @si ||= tab.snippet_inserter
      @buf ||= doc
      if @si.shift_tab_pressed
        # within a snippet
      else
        @buf.insert_at_cursor("\t")
      end
    end
  end
end
