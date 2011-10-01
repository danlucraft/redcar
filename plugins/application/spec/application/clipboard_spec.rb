require "spec_helper"

describe Redcar::Clipboard do
  before do
    @clipboard = Redcar::Clipboard.new("test")
  end
  
  it "accepts new contents" do
    @clipboard << "havelock"
    @clipboard.last.should == ["havelock"]
  end
  
  it "reports its length" do
    @clipboard.length.should == 0
    @clipboard << "havelock"
    @clipboard.length.should == 1
    @clipboard << "havelock2"
    @clipboard.length.should == 2
  end
  
  it "lets you get the items in reverse order" do
    @clipboard << "havelock"
    @clipboard << "samuel"
    @clipboard << "sybil"
    @clipboard[2].should == ["havelock"]
    @clipboard[1].should == ["samuel"]
    @clipboard[0].should == ["sybil"]
  end

  it "loads well when the clipboard starts as blank" do
    cont = "fake controller"
    def cont.changed?; true; end
    def cont.last_set=(something); @a = something;end
    def cont.get_contents; @a; end
    @clipboard.controller = cont
    @clipboard.length.should == 0 # shouldn't blow up
  end
  
  it "should allow for the controller to return contents" do
    cont = "fake controller"
    def cont.changed?; true; end
    def cont.last_set=(something); @a = something;end
    def cont.get_contents; @a; end
    @clipboard.controller = cont
    @clipboard << "yo"
    @clipboard.length.should == 2
  end
  
  it "has a maximum length" do
    (Redcar::Clipboard.max_length + 1).times do |i|
      @clipboard << "foo#{i}"
    end
    @clipboard.length.should == Redcar::Clipboard.max_length
  end
end
