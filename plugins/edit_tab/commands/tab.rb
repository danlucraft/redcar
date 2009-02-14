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
        if Redcar::Preference.get("Editing/Use spaces instead of tabs").to_bool
          @buf.insert_at_cursor(" "*Redcar::Preference.get("Editing/Indent size").to_i)
        else
          @buf.insert_at_cursor("\t")
        end
      end
    end
  end
end

