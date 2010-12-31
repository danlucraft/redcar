require File.join(File.dirname(__FILE__), '..', 'spec_helper')

class Redcar::REPL
  describe ReplMirror do
    before do
      @mirror = ReplMirror.new
      @changed_event = false
      @mirror.add_listener(:change) { @changed_event = true }
    end

    describe "has special commands" do
      it "gives usage assistance" do
        @mirror.evaluate('help')
        @mirror.history.include?(@mirror.help).should == true
      end

      it "clears command output" do
        ['1','2','3'].each {|cmd| @mirror.add_command(cmd)}
        @mirror.evaluate('clear')
        @mirror.history.should == @mirror.prompt + " "
      end

      it "resets command history" do
        ['1','2','3'].each {|cmd| @mirror.add_command(cmd)}
        @mirror.evaluate('reset')
        @mirror.command_history.should == []
        @mirror.history.should == @mirror.initial_preamble
        Redcar::REPL.storage['command_history'][@mirror.title].should == []
      end
    end

    describe "has command history" do
      it "should be empty initially" do
        @mirror.command_history.should == []
      end

      describe "adding and navigating command history" do
        before(:each) do
          Redcar::REPL.storage['command_history'][@mirror.title] = []
          ['1','2','3'].each {|cmd| @mirror.add_command(cmd)}
        end

        it "should add new commands" do
          @mirror.command_history.size.should == 3
        end

        it "should retrieve previous commands in order" do
          @mirror.previous_command.should == "3"
          @mirror.previous_command.should == "2"
          @mirror.previous_command.should == "1"
          @mirror.previous_command.should == nil
        end

        it "should retrieve next commands in order" do
          @mirror.previous_command.should == "3"
          @mirror.previous_command.should == "2"
          @mirror.previous_command.should == "1"
          @mirror.next_command.should == "2"
          @mirror.next_command.should == "3"
          @mirror.next_command.should == nil
        end

        it "should have a maximum size" do
          @mirror.set_buffer_size 3
          ['4','5'].each {|cmd| @mirror.add_command(cmd)}
          @mirror.command_history.size.should == 3
          @mirror.command_history.should == ['3','4','5']
        end
      end
    end
  end
end
