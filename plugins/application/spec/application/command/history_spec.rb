require "spec_helper"

describe Redcar::Command::History do
  class HistoryTestCommand1 < Redcar::Command
    def execute
    end
  end
  
  class HistoryTestCommand2 < Redcar::Command
    norecord
    
    def execute
    end
  end
  
  before do
    @history = Redcar::Command::History.new
  end
  
  it "should record executed commands" do
    command = HistoryTestCommand1.new
    @history.record(command)
    @history.length.should == 1
  end
  
  it "should not record norecord commands" do
    command = HistoryTestCommand2.new
    @history.record(command)
    @history.length.should == 0
  end
  
  it "should have a maximum length" do
    @history.max = 5
    10.times { @history.record(HistoryTestCommand1.new) }
    @history.length.should == 5
  end  
  
  it "should record and replace last if required" do
    @history.record(HistoryTestCommand1.new)
    @history.length.should == 1
    new_command = HistoryTestCommand1.new
    @history.record_and_replace(new_command)
    @history.length.should == 1
    @history.last.should == new_command
  end
end



