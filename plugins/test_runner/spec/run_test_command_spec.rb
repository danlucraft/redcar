require File.join(File.dirname(__FILE__), 'spec_helper')

describe Redcar::RunTestCommand do
  describe "calling run_test" do
    before do
      storage_file = File.join(Redcar.user_dir, "storage", "test_runner.yaml")
      FileUtils.rm(storage_file) if File.exists?(storage_file)
      Redcar::RunTestCommand.class_eval { @storage = nil}
      @run_test_command = Redcar::RunTestCommand.new
      Redcar::Project::Manager.stub!(:focussed_project).and_return(mock("project", {:path => "foo"}))
    end
    describe "with a test_unit test" do
      before do
        @test_path = "foo/bar/foo_test.rb"
      end
      describe "with a line that doesn't match a pattern" do
        it "should run the test file" do
          Redcar::Runnables.should_receive(:run_process).with(
            "foo", "ruby -Itest #{@test_path}", "Running test: foo_test.rb")
          @run_test_command.run_test(@test_path, "whatever")
        end
      end
      describe "with a line that matches a pattern" do
        it "should run the test file" do
          Redcar::Runnables.should_receive(:run_process).with(
            "foo", "ruby -Itest #{@test_path} -n \"/this is a context/\"", "Running test: this is a context")
          @run_test_command.run_test(@test_path, %{context "this is a context"})
        end
      end
    end
    describe "with an rspec2 spec" do
      before do
        @test_path = "foo/bar/foo_spec.rb"
      end
      describe "with a line that doesn't match a pattern" do
        it "should run the test file" do
          Redcar::Runnables.should_receive(:run_process).with(
            "foo", "ruby -Ispec #{@test_path}", "Running test: foo_spec.rb")
          @run_test_command.run_test(@test_path, "whatever")
        end
      end
      describe "with a line that matches a pattern" do
        it "should run the test file" do
          Redcar::Runnables.should_receive(:run_process).with(
            "foo", %{ruby -Ispec #{@test_path} -e "this is a context"}, "Running test: this is a context")
          @run_test_command.run_test(@test_path, %{describe "this is a context"})
        end
      end
    end
  end
end