module Redcar
  module Cucumber
    def self.run_cukes(args)
      require 'cucumber/cli/main'
      main = Cucumber::Cli::Main.new(["features/menu.feature", "--no-diff"])
      main.execute!(Cucumber::StepMother.new)
    end
    
    Thread.new do
      begin
        sleep 5
        run_cukes
      rescue Object => e
        puts e.message
        puts e.backtrace
      end
    end
  end
end