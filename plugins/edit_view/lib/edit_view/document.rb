
module Redcar
  class Document
    include Redcar::Observable
    
    def initialize(edit_tab)
      @edit_tab = edit_tab
    end
  end
end
