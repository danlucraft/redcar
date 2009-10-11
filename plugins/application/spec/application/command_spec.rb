require File.join(File.dirname(__FILE__), "..", "spec_helper")

describe Redcar::Command do
  describe "a command" do
    class MyCommand < Redcar::Command
      key "Ctrl+K"
    end

    it "stores the keybinding " do
      MyCommand.get_key.should == "Ctrl+K"
    end
  
    it "is recordable by default" do
      MyCommand.record?.should be_true
    end
  end
  
  describe "a non-recordable command" do
    class MyNonRecordableCommand < Redcar::Command
      norecord
    end
    
    it "is not recordable" do
      MyNonRecordableCommand.record?.should be_false
    end
  end
end