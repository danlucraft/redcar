module Redcar
  class RubyEnd < Redcar::RubyCommand
    key   "Ctrl+Alt+E"

    def execute
      doc.insert_at_cursor("en")
      doc.type("d")
    end
  end
end
