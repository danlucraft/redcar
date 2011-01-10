module Redcar
  class RspecRunner
    TEST_PATTERNS = [
      /context\s+\"(.*)\"/,
      /describe\s+\"(.*)\"/,
      /it\s+\"(.*)\"/
    ]
    
    def self.run_test(path, current_line)
      TEST_PATTERNS.each do |pattern|
        if current_line =~ pattern
          Redcar::Runnables.run_process Project::Manager.focussed_project.path, %{ruby -Ispec #{path} -e "#{$1}"}, "Running spec: #{$1}"
          return
        end
      end
      Redcar::Runnables.run_process Project::Manager.focussed_project.path, %{ruby -Ispec #{path}}, "Running spec: #{File.basename(path)}"
    end
  end
end
  