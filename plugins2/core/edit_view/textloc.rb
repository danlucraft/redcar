
def TextLoc(a, b)
  Redcar::TextLoc.new(a, b)
end

module Redcar  
  class TextLoc
    def copy
      TextLoc.new(self.line, self.offset)
    end
  end 
end
