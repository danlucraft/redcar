
module Cucumber
  module Ast
    class StepInvocation #:nodoc:#
      class << self
        attr_accessor :wait_time
      end

      def invoke_with_swt(step_mother, options)
        block = Swt::RRunnable.new { invoke_without_swt(step_mother, options) }

        Redcar::ApplicationSWT.display.syncExec(block)
        sleep ENV["SLOW_CUKES"].to_f if ENV["SLOW_CUKES"]
        sleep(Cucumber::Ast::StepInvocation.wait_time || 0)
        Cucumber::Ast::StepInvocation.wait_time = nil
      end

      alias_method :invoke_without_swt, :invoke
      alias_method :invoke, :invoke_with_swt
    end
  end

  module Cli
    class Configuration
      def require_dirs_with_redcar_plugins
        require_dirs_without_redcar_plugins + Dir['plugins/*/features']
      end

      alias_method :require_dirs_without_redcar_plugins, :require_dirs
      alias_method :require_dirs, :require_dirs_with_redcar_plugins
    end
  end
end