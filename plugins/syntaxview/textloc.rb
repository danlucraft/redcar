
def TextLoc(a, b)
  Redcar::TextLoc.new(a, b)
end

module Redcar  
  class TextLoc
     attr_reader :line, :offset
    
     def initialize(line, offset)
       @line = line
       @offset = offset
     end
    
    def copy
      TextLoc.new(self.line, self.offset)
    end
    
    def ==(other)
      other and @line == other.line and @offset == other.offset
    end  
    
    def <(other)
      if self.line < other.line
        return true
      elsif self.line == other.line
        if self.offset < other.offset
          return true
        else
          return false
        end
      else
        return false
      end
    end
    
    def >(other)
      if self.line > other.line
        return true
      elsif self.line == other.line
        if self.offset > other.offset
          return true
        else
          return false
        end
      else
        return false
      end
    end
    
    def <=(other)
      if self.line < other.line
        return true
      elsif self.line == other.line
        if self.offset < other.offset
          return true
        elsif self.offset == other.offset
          return true
        else
          return false
        end
      else
        return false
      end
    end
    
    def >=(other)
      sl = self.line
      ol = other.line
      if sl > ol
        return true
      elsif sl == ol
        so = self.offset
        oo = other.offset
        if so > oo
          return true
        elsif so == oo
          return true
        else
          return false
        end
      else
        return false
      end
    end
  end
end
