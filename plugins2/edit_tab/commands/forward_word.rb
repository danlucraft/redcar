module Redcar
  class ForwardWord < Redcar::EditTabCommand
    key  "Ctrl+F"
    icon :GO_FORWARD
    
    def execute
      doc.forward_word
    end
  end
end

