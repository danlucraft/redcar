
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
  module Formatter
    class SwtFormatter < Pretty
      
      def visit_step(*)
        block = RRunnable.new do
          super
        end
        # TODO: Wo! Back references already!
        Redcar::ApplicationSWT.display.syncExec(block)
        if time_str = ENV['GUTKUMBER_SLEEP']
          sleep time_str.to_f
        end
      end
    end
  end
  
  module Ast
    class TreeWalker
      def visit_steps(steps)
        broadcast(steps) do
          block = RRunnable.new do
            steps.accept(self)
          end
          # TODO: Wo! Back references already!
          Redcar::ApplicationSWT.display.syncExec(block)
        end
      end

      def visit_step(step)
        broadcast(step) do
          block = RRunnable.new do
            step.accept(self)
          end
          # TODO: Wo! Back references already!
          Redcar::ApplicationSWT.display.syncExec(block)
        end
      end
    end
  end
end
