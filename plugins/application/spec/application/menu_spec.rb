require File.join(File.dirname(__FILE__), "..", "spec_helper")

describe Redcar::Menu do
  class DummyCommand; end
  
  describe "with nothing in it and no text" do
    before do
      @menu = Redcar::Menu.new
    end

    it "should accept items" do
      @menu << Redcar::MenuItem.new("File", DummyCommand)
    end

    it "reports length" do
      @menu.length.should == 0
    end
  end  
  
  describe "with items and other menus in it and text" do
    before do
      @menu = Redcar::Menu.new("Edit")
      @menu << Redcar::MenuItem.new("Cut", DummyCommand)
      @menu << Redcar::MenuItem.new("Paste", DummyCommand)
      @menu << Redcar::Menu.new("Convert")
    end

    it "reports length" do
      @menu.length.should == 3
    end
    
    it "has text" do
      @menu.text.should == "Edit"
    end
  end
end