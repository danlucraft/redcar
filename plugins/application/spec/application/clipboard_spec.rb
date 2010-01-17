require File.join(File.dirname(__FILE__), "..", "spec_helper")

describe Redcar::Clipboard do
  before do
    @clipboard = Redcar::Clipboard.new("test")
  end
  
  it "accepts new contents" do
    @clipboard << "havelock"
    @clipboard.last.should == ["havelock"]
  end
  
  it "reports it's length" do
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
  
  it "has a maximum length" do
    (Redcar::Clipboard.max_length + 1).times do |i|
      @clipboard << "foo#{i}"
    end
    @clipboard.length.should == Redcar::Clipboard.max_length
  end
end
