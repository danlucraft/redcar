module Redcar
  class RunnableTestRunner
    
    attr_accessor :single_test_patterns, :file_runner, :single_test_runner
    
    def initialize(config)
      @single_test_patterns = config["single_test_patterns"]
      @single_test_runner = config["single_test_runner"]
      @file_runner = config["file_runner"]
    end
    
    def run_test(path, current_line)
      single_test_patterns.each do |pattern|
        if current_line =~ pattern
          test_name = $1
          command = single_test_runner.gsub("__FILE__", path).gsub("__TEST_NAME__", test_name)
          Redcar::Runnables.run_process Project::Manager.focussed_project.path, command, "Running test: #{test_name}"
          return
        end
      end
      Redcar::Runnables.run_process Project::Manager.focussed_project.path,
        file_runner.gsub("__FILE__", path), "Running test: #{File.basename(path)}"
    end
  end
end
  