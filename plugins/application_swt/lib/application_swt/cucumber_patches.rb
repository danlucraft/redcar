
module Cucumber
  
  module Ast
    class TreeWalker
      def visit_steps(steps)
        broadcast(steps) do
          block = Swt::RRunnable.new do
            steps.accept(self)
          end
          Redcar::ApplicationSWT.display.syncExec(block)
        end
      end

      def visit_step(step)
        broadcast(step) do
          block = Swt::RRunnable.new do
            step.accept(self)
          end
          Redcar::ApplicationSWT.display.syncExec(block)
        end
      end
    end
  end
end
