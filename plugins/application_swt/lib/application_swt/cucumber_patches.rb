
class RRunnable
  include java.lang.Runnable

  def initialize(&block)
    @block = block
  end

  def run
    @block.call
  end
end

module Cucumber
  
  module Ast
    class TreeWalker
      def visit_steps(steps)
        broadcast(steps) do
          block = RRunnable.new do
            steps.accept(self)
          end
          Redcar::ApplicationSWT.display.syncExec(block)
        end
      end

      def visit_step(step)
        broadcast(step) do
          block = RRunnable.new do
            step.accept(self)
          end
          Redcar::ApplicationSWT.display.syncExec(block)
        end
      end
    end
  end
end
