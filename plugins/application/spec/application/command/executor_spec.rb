require File.join(File.dirname(__FILE__), "..", "..", "spec_helper")

class Redcar::Command
  describe Executor, "running a command" do
  
    class MyCommand < Redcar::Command
      def environment(env)
        $spec_executor_env = env
      end
      
      def execute
        $spec_executor_ran_command = true
      end
    end
  
    before do
      Executor.stub!(:current_environment).and_return(:current_environment)
      $spec_executor_env         = nil
      $spec_executor_ran_command = false
      Redcar.history = History.new
      @command  = MyCommand.new
      @executor = Executor.new(@command)
    end
  
    it "should call execute on the Command" do
      @executor.execute
      $spec_executor_ran_command.should be_true
    end
    
    it "should add the command to the History" do
      @executor.execute
      Redcar.history.last.should == @command
    end
    
    it "should set the command environment" do
      @executor.execute
      $spec_executor_env.should == :current_environment
    end
  end
end