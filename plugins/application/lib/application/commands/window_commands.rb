module Redcar
  class Application
    class CloseWindowCommand < Command
      def initialize(window=nil)
        @window = window
      end

      def execute
        Redcar.app.call_on_plugins(:close_window_guard, win) do |guard|
          return unless guard
        end
        win.close
        quit_if_no_windows if [:linux, :windows].include?(Redcar.platform)
        @window = nil
      end

      private

      def quit_if_no_windows
        if Redcar.app.windows.length == 0
          if Application.storage['stay_resident_after_last_window_closed'] && !(ARGV.include?("--multiple-instance"))
            puts 'continuing to run to wait for incoming drb connections later'
          else
            QuitCommand.new.run
          end
        end
      end

      def win
        @window || super
      end
    end

  end
end