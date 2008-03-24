
def TextLoc(a, b)
  Redcar::EditView::TextLoc.new(a, b)
end

class Redcar::EditView
  class TextLoc
    def copy
      TextLoc.new(self.line, self.offset)
    end
  end 
end
