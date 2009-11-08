require File.join(File.dirname(__FILE__), "..", "spec_helper")

class Redcar::REPL
  describe InternalMirror do
    it "should exist" do
      InternalMirror.should be_an_instance_of(Class)
    end
  end
end