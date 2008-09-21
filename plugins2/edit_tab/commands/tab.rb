module Redcar
  class TabPressed < Redcar::EditTabCommand
    key "Tab"
    norecord
    
    def initialize(si=nil, buf=nil)
      @si = si
      @buf = buf
    end
    
    def execute
      @si ||= tab.snippet_inserter
      @buf ||= doc
      if snippet = @si.tab_pressed
        #          InsertSnippet.new(snippet).do
      else
        @buf.insert_at_cursor("\t")
        #          InsertTab.new(@buf).do
      end
    end
  end
end

