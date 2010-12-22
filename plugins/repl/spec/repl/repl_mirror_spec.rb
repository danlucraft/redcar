require File.join(File.dirname(__FILE__), '..', 'spec_helper')

class Redcar::REPL
  describe ReplMirror do
    before do
      @mirror = ReplMirror.new
      @changed_event = false
      @mirror.add_listener(:change) { @changed_event = true }
    end

    describe "command history" do
      it "should be empty initially" do
        @mirror.command_history.should == []
      end

      it "should add new commands" do
        ['1','2','3'].each {|cmd| @mirror.add_command(cmd)}
        @mirror.command_history.size.should == 3
      end

      it "should retrieve previous commands in order" do
        ['1','2','3'].each {|cmd| @mirror.add_command(cmd)}
        @mirror.previous_command.should == "3"
        @mirror.previous_command.should == "2"
        @mirror.previous_command.should == "1"
      end

      it "should retrieve next commands in order" do
        ['1','2','3'].each {|cmd| @mirror.add_command(cmd)}
        @mirror.previous_command.should == "3"
        @mirror.previous_command.should == "2"
        @mirror.previous_command.should == "1"
        @mirror.next_command.should == "2"
        @mirror.next_command.should == "3"
        @mirror.next_command.should == ""
      end

      it "should have a maximum size" do
        @mirror.command_history_buffer_size = 3
        ['1','2','3','4','5'].each {|cmd| @mirror.add_command(cmd)}
        @mirror.command_history.size.should == 3
        @mirror.command_history.should == ['3','4','5']
      end
    end
  end
end