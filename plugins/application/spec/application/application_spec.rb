require File.join(File.dirname(__FILE__), "..", "spec_helper")

describe Redcar::Application do
  it "has a name" do
    Redcar::Application::NAME.should_not be_nil
  end
  
  it "has a default instance" do
    Redcar.app.is_a? Redcar::Application
  end
  
  describe "instance" do
    it "creates a new window" do
      Redcar.app.new_window
      Redcar.app.windows.length.should == 1
    end
  end
end