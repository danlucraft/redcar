
module Redcar
  class AutocompleteWord < Redcar::Command
    key "Escape"
    menu "Edit/Autocomplete Word"
    
    def execute
      puts "Autocomplete word called."
    end
  end
end

