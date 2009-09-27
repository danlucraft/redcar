require File.join(File.dirname(__FILE__), "..", "spec_helper")

describe Redcar::Application::Menu do
  class DummyCommand; end
  
  describe "with no entries and no text" do
    before do
      @menu = Redcar::Application::Menu.new
    end

    it "should accept items" do
      @menu << Redcar::Application::MenuItem.new("File", DummyCommand)
    end

    it "reports length" do
      @menu.length.should == 0
    end
  end  
  
  describe "with entries in it and text" do
    before do
      @menu = Redcar::Application::Menu.new("Edit") \
                  << Redcar::Application::MenuItem.new("Cut", DummyCommand) \
                  << Redcar::Application::MenuItem.new("Paste", DummyCommand) \
                  << Redcar::Application::Menu.new("Convert")
    end

    it "reports length" do
      @menu.length.should == 3
    end
    
    it "has text" do
      @menu.text.should == "Edit"
    end
  end
end