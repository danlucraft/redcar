require File.join(File.dirname(__FILE__), "..", "spec_helper")

describe Redcar::Menu do
  class DummyCommand; end
  
  describe "with no entries and no text" do
    before do
      @menu = Redcar::Menu.new
    end

    it "should accept items" do
      @menu << Redcar::Menu::Item.new("File", DummyCommand)
    end

    it "reports length" do
      @menu.length.should == 0
    end
  end  
  
  describe "with entries in it and text" do
    before do
      @menu = Redcar::Menu.new("Edit") \
                  << Redcar::Menu::Item.new("Cut", DummyCommand) \
                  << Redcar::Menu::Item.new("Paste", DummyCommand) \
                  << Redcar::Menu.new("Convert")
    end

    it "reports length" do
      @menu.length.should == 3
    end
    
    it "has text" do
      @menu.text.should == "Edit"
    end
  end
end