require File.join(File.dirname(__FILE__), "..", "spec_helper")

describe Redcar::Notebook do
  describe "with no tabs" do
    class NotebookTestTab < Redcar::Tab
    end
    
    before do
      @notebook = Redcar::Notebook.new(nil)
      @app = mock
      Redcar.stub!(:app).and_return(@app)
    end
    
    it "reports its length" do
      @notebook.length.should == 0
    end
    
    it "accepts new tabs and reports them to the controller" do
      tab_result = nil
      @notebook.add_listener(:tab_added) do |tab|
        tab_result = tab
      end
      @app.should_receive(:call_on_plugins)
      
      @notebook.new_tab NotebookTestTab
      
      tab_result.should be_an_instance_of(NotebookTestTab)
    end
  end
end
    