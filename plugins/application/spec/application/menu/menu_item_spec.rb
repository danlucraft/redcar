require "spec_helper"

describe Redcar::Menu::Item do
  class DummyCommand; end
  
  before do
    @menu_item = Redcar::Menu::Item.new("File", DummyCommand)
  end

  it "has text" do
    @menu_item.text.should == "File"
  end

  it "has a command" do
    @menu_item.command.should == DummyCommand
  end
end
