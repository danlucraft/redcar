
describe Redcar::CommandHistory do
  class HistoryTestCommand < Redcar::Command
    def execute
    end
  end
  
  class HistoryTestCommand2 < Redcar::Command
    norecord
    def execute
    end
  end
  
  class HistoryTestCommand3 < Redcar::Command
    def execute
    end
  end
  
  before(:each) do
    Redcar::CommandHistory.clear
  end
  
  it "should record executed commands" do
    HistoryTestCommand.new.do
    Redcar::CommandHistory.length.should == 1
    Redcar::CommandHistory.first.class.should == HistoryTestCommand
  end
  
  it "should not record norecord commands" do
    HistoryTestCommand2.new.do
    Redcar::CommandHistory.length.should == 0
  end
  
  it "should have a maximum length" do
    Redcar::CommandHistory.max = 5
    10.times { HistoryTestCommand.new.do }
    Redcar::CommandHistory.length.should == 5
    Redcar::CommandHistory.max = 500
  end  
  
  it "should replace last if required" do
    HistoryTestCommand.new.do
    Redcar::CommandHistory.length.should == 1
    new_command = HistoryTestCommand.new
    new_command.do(:replace_previous => true)
    Redcar::CommandHistory.length.should == 1
    Redcar::CommandHistory.last.should == new_command
  end
end



