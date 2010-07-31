module Redcar
  class ApplicationSWT
    class CucumberRunner
      START_DELAY = 1
    
      def run_features(args)
        require "cucumber/cli/main"
        require "cucumber"
        require "cucumber/rb_support/rb_language"
        require "application_swt/cucumber_patches"
        Thread.new do
          begin
            sleep START_DELAY
            main = Cucumber::Cli::Main.new(args)
            main.execute!(Cucumber::StepMother.new)
            Redcar.update_gui { Redcar::ApplicationSWT.display.dispose }
            Redcar.app.quit
            java.lang.Runtime.getRuntime.exit(0)
          rescue Object => e
            puts e.message
            puts e.backtrace
          end
        end
      end
    end
  end
end
