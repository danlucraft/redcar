require File.join(File.dirname(__FILE__), "..", "..", "spec_helper")

describe "Redcar::Keymap::Builder DSL" do
  it "creates a keymap" do
    builder = Redcar::Keymap::Builder.new("test", :osx) {}
    builder.keymap.should be_an_instance_of(Redcar::Keymap)
    builder.keymap.length.should == 0
  end
  
  it "add entries to the keymap" do
    builder = Redcar::Keymap::Builder.new("test", :osx) do
      link "Ctrl+S", :OpenNewEditTabCommand
    end
    builder.keymap.length.should == 1
    builder.keymap.command("Ctrl+S")
  end
end