require File.join(File.dirname(__FILE__), "..", "spec_helper")

describe Redcar::Notebook do
  describe "with no tabs" do
    before do
      @notebook = Redcar::Notebook.new
    end
    
    it "reports its length" do
      @notebook.length.should == 0
    end
    
    it "accepts new tabs and reports them to the controller" do
      tab_result = nil
      @notebook.add_listener(:tab_added) do |tab|
        tab_result = tab
      end
      @notebook << 12301
      tab_result.should == 12301
    end
  end
end
    