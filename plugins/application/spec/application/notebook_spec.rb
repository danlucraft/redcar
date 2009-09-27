require File.join(File.dirname(__FILE__), "..", "spec_helper")

describe Redcar::Notebook do
  describe "with no tabs" do
    before do
      @notebook = Redcar::Notebook.new
      @notebook.controller = RedcarSpec::NotebookController.new
    end
    
    it "reports its length" do
      @notebook.length.should == 0
    end
    
    it "accepts new tabs and reports them to the controller" do
      tab = Redcar::Tab.new
      @notebook.controller.should_receive(:tab_added).with(tab)
      @notebook << tab
    end
  end
end
    