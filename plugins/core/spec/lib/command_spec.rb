
describe Redcar::Command do
  before(:each) do
    Redcar::CloseAllTabs.new.do
  end

  after(:each) do
    Redcar::CloseAllTabs.new.do
  end

	class TestCommand < Redcar::EditTabCommand
		def execute
			@saved_input = input
		end
	end
	
	describe "input" do
    before(:each) do
      @tab = Redcar::NewTab.new.do
      @tab.document.text = "foo\nbar\nbaz\n"
      @tab.document.cursor = 1
    end
  		
    it "should get input as line" do
      TestCommand.input(:line)
      tc = TestCommand.new
      tc.set_tab(@tab)
      tc.input.should == "foo\n"
    end
  end
end



