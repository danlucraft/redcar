# These are broken and I don't understand why - danlucraft 1/10/11

# require 'spec_helper'
# 
# describe Redcar::RunTestCommand do
#   describe "calling run_test" do
#     before do
#       storage_file = File.join(Redcar.user_dir, "storage", "test_runner.yaml")
#       FileUtils.rm(storage_file) if File.exists?(storage_file)
#       Redcar::RunTestCommand.class_eval { @storage = nil}
#       @run_test_command = Redcar::RunTestCommand.new
#       Redcar::Project::Manager.stub!(:focussed_project).and_return(mock("project", {:path => "foo"}))
#     end
#     
#     describe "with a test_unit test" do
#       before do
#         @test_path = "foo/bar/foo_test.rb"
#       end
#       
#       describe "with a line that doesn't match a pattern" do
#         it "should run the test file" do
#           @run_test_command.should_receive(:run_process).with(
#             "ruby -Itest __PATH__", "Running test: foo_test.rb")
#           @run_test_command.run_test(@test_path, "whatever")
#         end
#       end
#       
#       describe "with a line that matches a pattern" do
#         it "should run the test file" do
#           @run_test_command.should_receive(:run_process).with(
#             "ruby -Itest __PATH__ -n \"/this is a context/\"", "Running test: this is a context")
#           @run_test_command.run_test(@test_path, %{context "this is a context"})
#         end
#       end
#     end
#     
#     describe "with an rspec2 spec" do
#       before do
#         @test_path = "foo/bar/foo_spec.rb"
#       end
#       
#       describe "with a line that doesn't match a pattern" do
#         it "should run the test file" do
#           @run_test_command.should_receive(:run_process).with(
#             "ruby -Ispec __PATH__", "Running test: foo_spec.rb")
#           @run_test_command.run_test(@test_path, "whatever")
#         end
#       end
#       
#       describe "with a line that matches a pattern" do
#         it "should run the test file" do
#           @run_test_command.should_receive(:run_process).with(
#             %{ruby -Ispec __PATH__ -e "this is a context"}, "Running test: this is a context")
#           @run_test_command.run_test(@test_path, %{describe "this is a context"})
#         end
#       end
#     end
#   end
# end