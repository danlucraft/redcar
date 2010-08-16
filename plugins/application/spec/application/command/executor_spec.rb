require File.join(File.dirname(__FILE__), "..", "..", "spec_helper")

class Redcar::Command
  describe Executor do
    class FakeApp
      attr_accessor :history
    end
    
    before do
      Executor.stub!(:current_environment).and_return(:current_environment)
      Redcar.app = FakeApp.new
      Redcar.app.history = History.new
    end
    
    describe "executing a command" do
      class MyCommand < Redcar::Command
        def environment(env)
          $spec_executor_env = env
        end

        def execute
          $spec_executor_ran_command = true
        end
      end

      before do
        $spec_executor_env         = nil
        $spec_executor_ran_command = false
        @command  = MyCommand.new
        @executor = Executor.new(@command)
      end
  
      it "should call execute on the Command" do
        @executor.execute
        $spec_executor_ran_command.should be_true
      end
    
      it "should add the command to the History" do
        @executor.execute
        Redcar.app.history.last.should == @command
      end
    
      it "should set the command environment" do
        @executor.execute
        $spec_executor_env.should == :current_environment
      end
    end
    
    describe "executing command capturing errors" do
      class MyErrorCommand < Redcar::Command
        def execute
          raise "hell"
        end
      end
      
      before do
        @command = MyErrorCommand.new
        @executor = Executor.new(@command)
        $stdout = StringIO.new
      end
      
      after do
        $stdout = STDOUT
      end

      it "should capture the error" do
        lambda { @executor.execute }.should_not raise_error
      end
      
      it "should store the error in the class" do
        @executor.execute
        @command.error.should be_an_instance_of(RuntimeError)
        @command.error.message.should == "hell"
      end
    end
  end
end