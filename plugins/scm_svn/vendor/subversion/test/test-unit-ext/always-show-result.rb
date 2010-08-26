require "test/unit/ui/testrunnermediator"

module Test
  module Unit
    module UI
      class TestRunnerMediator
        alias_method :original_run_suite, :run_suite
        def run_suite
          @notified_finished = false
          begin_time = Time.now
          original_run_suite
        rescue Interrupt
          unless @notified_finished
            end_time = Time.now
            elapsed_time = end_time - begin_time
            notify_listeners(FINISHED, elapsed_time)
          end
          raise
        end

        def notify_listeners(channel_name, *arguments)
          @notified_finished = true if channel_name == FINISHED
          super
        end
      end
    end
  end
end
