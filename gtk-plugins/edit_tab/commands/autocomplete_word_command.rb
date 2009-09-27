
module Redcar
  class AutocompleteWordCommand < Redcar::EditTabCommand
    key "Escape"
    norecord
    
    def execute
      @autocompleter ||= tab.view.autocompleter
      @buf ||= doc
      
      @autocompleter.complete_word
    end
  end
end

