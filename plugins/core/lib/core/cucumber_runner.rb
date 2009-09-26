module Redcar
  module CucumberRunner
    START_DELAY = 1
    
    def self.run_cukes(args)
      require 'cucumber/cli/main'
      Thread.new do
        begin
          sleep START_DELAY
          main = Cucumber::Cli::Main.new(args)
          main.execute!(Cucumber::StepMother.new)
          Redcar.app.quit
        rescue Object => e
          puts e.message
          puts e.backtrace
        end
      end
    end
  end
end