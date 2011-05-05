module Redcar
  
  class RunTestCommand < Redcar::Command
    
    TEST_RUNNERS = {
      "Redcar::TestUnitRunner" => /_test.rb$/,
      "Redcar::RspecRunner" => /_spec.rb$/
    }
    
    def self.storage
      @storage ||= begin
        storage = Plugin::Storage.new('test_runner')
        storage.set_default('test_runners', [
          {
            "runner_class" => "Redcar::RunnableTestRunner",
            "file_pattern" => /_test.rb$/,
            "single_test_patterns" => [
              /should\s+\"(.*)\"/,
              /context\s+\"(.*)\"/,
              /describe\s+\"(.*)\"/,
              /def\s+(test_.*)\s+/
            ],
            "single_test_runner" => "ruby -Itest __PATH__ -n \"/__TEST_NAME__/\"",
            "file_runner" => "ruby -Itest __PATH__"
          },
          {
            "runner_class" => "Redcar::RunnableTestRunner",
            "file_pattern" => /_spec.rb$/,
            "single_test_patterns" => [
              /it\s+\"(.*)\"/,
              /context\s+\"(.*)\"/,
              /describe\s+\"(.*)\"/
            ],
            "single_test_runner" => "ruby -Ispec __PATH__ -e \"__TEST_NAME__\"",
            "file_runner" => "ruby -Ispec __PATH__"
          },
        ])
        storage
      end
    end
    
    def test_runners
      self.class.storage["test_runners"]
    end
    
    def run_test(path, current_line)
      test_runners.each do |test_runner_config|
        pattern = test_runner_config["file_pattern"]
        if path =~ pattern
          runner = eval(test_runner_config["runner_class"]).new(test_runner_config)
          runner.run_test(path, current_line)
        end
      end
    end
    
    def execute
      doc = Redcar.app.focussed_window.focussed_notebook_tab.edit_view.document
      current_line = doc.get_line(doc.cursor_line)
      run_test(doc.path, current_line)
    end
  end
  
end