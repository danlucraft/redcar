module Redcar
  class TabPressed < Redcar::EditTabCommand
    key "Tab"
    norecord
    
    def initialize(si=nil, buf=nil)
      @si = si
      @buf = buf
    end
    
    def execute
      @si ||= tab.view.snippet_inserter
      @buf ||= doc
      if snippet = @si.tab_pressed
      else
        @buf.insert_at_cursor("\t")
      end
    end
  end
end

