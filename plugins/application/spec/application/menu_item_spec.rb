require File.join(File.dirname(__FILE__), "..", "spec_helper")

describe Redcar::MenuItem do
  it "has text" do
    @menu_item = Redcar::MenuItem.new("File")
    @menu_item.text.should == "File"
  end
end
