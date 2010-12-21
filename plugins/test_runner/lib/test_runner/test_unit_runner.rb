module Redcar
  class TestUnitRunner
    TEST_PATTERNS = [
      /should\s+\"(.*)\"/,
      /context\s+\"(.*)\"/,
      /describe\s+\"(.*)\"/,
      /it\s+\"(.*)\"/,
      /def\s+(test_.*)\s+/
    ]
    
    def self.run_test(path, current_line)
      TEST_PATTERNS.each do |pattern|
        if current_line =~ pattern
          Redcar::Runnables.run_process Project::Manager.focussed_project.path, %{ruby -Itest #{path} -n "/#{$1}/"}, "Running test: #{$1}"
          return
        end
      end
      Redcar::Runnables.run_process Project::Manager.focussed_project.path, %{ruby -Itest #{path}}, "Running test: #{File.basename(path)}"
    end
  end
end
  