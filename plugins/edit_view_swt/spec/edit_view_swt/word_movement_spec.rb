require "spec_helper"

describe Redcar::EditViewSWT::WordMoveListener do
  before do
    @word = Redcar::EditViewSWT::WordMoveListener.new(nil)
  end
  
  describe "moving forwards" do
    it "should move over a word to the next non-word char" do
      @word.next_offset(0, 0, "foo.bar").should == 3
    end
  
    it "should move over a symbol and a word to the next non-word char" do
      @word.next_offset(0, 0, ".foo.bar").should == 4
    end
  
    it "should move over multiple symbols to the next word" do
      @word.next_offset(0, 0, "..foo.bar").should == 2
    end
  
    it "should move over a space and the next word " do
      @word.next_offset(0, 0, " foo.bar").should == 4
    end
  
    it "should move over multiple spaces to the next word " do
      @word.next_offset(0, 0, "  foo.bar").should == 2
    end
  end
end