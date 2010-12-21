module Redcar
  
  class RunTestCommand < Redcar::Command
    
    TEST_RUNNERS = {
      Redcar::TestUnitRunner => /_test.rb$/,
      Redcar::RspecRunner => /_spec.rb$/
    }
    
    def run_test(path, current_line)
      TEST_RUNNERS.each_pair do |runner_class, pattern|
        runner_class.run_test(path, current_line) if path =~ pattern
      end
    end
    
    def single_test_specifier(path, name)
      if path =~ /_test\.rb$/
        "-n /#{name}/"
      else
        %{-e "#{name}"}
      end
    end
    
    def execute
      doc = Redcar.app.focussed_window.focussed_notebook_tab.edit_view.document
      current_line = doc.get_line(doc.cursor_line)
      run_test(doc.path, current_line)
    end
  end
  
end