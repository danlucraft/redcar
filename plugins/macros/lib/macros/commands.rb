
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
            Macros.recording[edit_view][:actions] << action
          end
          Macros.recording[edit_view] = {:subscriber => h, :actions => []}
        end
      end
    end
    
    class RunLastCommand < Redcar::DocumentCommand
      def execute
        macro = Macros.session_macros.last
        macro.run_in(edit_view)
      end
    end
    
    class NameLastMacroCommand < Redcar::Command
      def execute
        result = Application::Dialog.input("Macro Name", 
          "Assign a name to the last recorded macro:", "Nameless Macro :(")
        if result[:button] == :ok
          Macros.session_macros.last.name = result[:value]
        end
      end
    end
  end
end