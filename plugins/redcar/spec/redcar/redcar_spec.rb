require File.join(File.dirname(__FILE__), "..", "spec_helper")

class DocString

  def initialize string
   @string = string
   @cursor_offset = 0
  end
  attr_accessor :cursor_offset
  
  def cursor_line
    1
  end  
  
  def cursor_offset
    0
  end
  
  
  def set_selection_range(start, _end)
   # ignore
  end
  
  def scroll_to_line(n)
  end
  
  def get_line x
     out = @string.split("\n")[x]
     out
  end
  
  def line_count
    @string.split("\n").length
  end
   
  def offset_at_line x
   @string.split("\n")[0..x].join("\n").length  
  end
  
end

module Redcar::Top
 describe FindNextRegex do

  def setup regex, wrap = false
    @a = FindNextRegex.new regex, wrap
   
    def @a.doc
     DocString.new("a\nb\nc")
    end
  end
  
  it "should be able to search forward and fail" do
    setup /abc/
    @a.execute.should be_false
  end  
  
  it "should be able to search forward successfully" do
    setup /c/
    @a.execute.should be_true  
  end
  
  it "should be able to wrap search" do
    setup /a/, true
    @a.execute.should be_true  
  end
   
 end
 
end