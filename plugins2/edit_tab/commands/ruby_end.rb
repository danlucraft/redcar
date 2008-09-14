module Redcar
  class RubyEnd < Redcar::RubyCommand
    key   "Ctrl+Alt+E"
    menu "Edit/Ruby End"
    def execute
      doc.insert_at_cursor("en")
      doc.type("d\n")
    end
  end
end
