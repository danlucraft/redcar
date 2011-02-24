module Redcar
  class RunnableTestRunner
    
    attr_accessor :single_test_patterns, :file_runner, :single_test_runner, :other_notebook
    
    def initialize(config)
      @single_test_patterns = config["single_test_patterns"]
      @single_test_runner = config["single_test_runner"]
      @file_runner = config["file_runner"]
      @other_notebook = config["other_notebook"]
    end
    
    def run_test(path, current_line)
      single_test_patterns.each do |pattern|
        if current_line =~ pattern
          test_name = $1
          command = single_test_runner.gsub("__TEST_NAME__", test_name)
          run_process command, "Running test: #{test_name}"
          return
        end
      end
      run_process file_runner.dup, "Running test: #{File.basename(path)}"
    end
    
    def run_process(command, title)
      p [:command, command]
      current_tab = Redcar.app.focussed_window.focussed_notebook_tab
      Redcar::Runnables.run_process Project::Manager.focussed_project.path, command, title
      if other_notebook
        window = Redcar.app.focussed_window
        tab = Redcar.app.all_tabs.detect {|tab| tab.title == title }
        if current_tab.notebook == tab.notebook
          i = window.notebooks.index(tab.notebook)
          target_notebook = window.notebooks[ (i + 1) % window.notebooks.length ]
          target_notebook.grab_tab_from(tab.notebook, tab)
        end
        current_tab.focus
      end
    end
  end
end
  