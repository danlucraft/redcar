
def TextLoc(a, b)
  Redcar::EditView::TextLoc.new(a, b)
end

class Redcar::EditView
  class TextLoc
    def copy
      TextLoc.new(self.line, self.offset)
    end

    def valid?
      self.line != -1 and self.offset != -1
    end
    
    def inspect
      "#<TextLoc:#{self.object_id} (#{self.line}, #{self.offset})>"
    end
    
    def <=>(other)
      if self < other
        -1
      elsif self > other
        1
      elsif self == other
        0
      else
        raise "<=> TextLoc error"
      end
    end
  end 
end
