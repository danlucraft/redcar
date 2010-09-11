
module Redcar
  module Macros
    class StartStopRecordingCommand < Redcar::DocumentCommand
      def execute
        if info = Macros.recording[edit_view]
          edit_view.history.unsubscribe(info[:subscriber])
          Macros.session_macros << Macro.new(info[:actions])
          Macros.recording[edit_view] = nil
        else
          h = edit_view.history.subscribe do |action|
            p [:record, action]
            Macros.recording[edit_view][:actions] << action
          end
          Macros.recording[edit_view] = {:subscriber => h, :actions => []}
        end
      end
    end
    
    class RunLastCommand < Redcar::DocumentCommand
      def execute
        p :RunLastCommand
        p Macros.session_macros.last
      end
    end
  end
end