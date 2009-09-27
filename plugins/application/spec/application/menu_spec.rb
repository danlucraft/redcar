require File.join(File.dirname(__FILE__), "..", "spec_helper")

describe Redcar::Menu do
  describe "with nothing in it" do
    before do
      @menu = Redcar::Menu.new
    end

    it "should accept items" do
      @menu << Redcar::MenuItem.new("File")
    end

    it "reports length" do
      @menu.length.should == 0
    end
  end  
  
  describe "with items in it" do
    before do
      @menu = Redcar::Menu.new
      @menu << Redcar::MenuItem.new("File")
      @menu << Redcar::MenuItem.new("Edit")
    end

    it "reports length" do
      @menu.length.should == 2
    end
  end
end