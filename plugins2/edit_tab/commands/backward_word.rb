module Redcar
  class BackwardWord < Redcar::EditTabCommand
    key  "Ctrl+B"
    icon :GO_BACK

    def execute
      doc.backward_word
    end
  end

end
