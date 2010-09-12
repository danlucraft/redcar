
module Redcar
  module Macros
    class StartStopRecordingCommand < Redcar::DocumentCommand
      def execute
        if info = Macros.recording[edit_view]
          edit_view.history.unsubscribe(info[:subscriber])
          macro = Macro.new(info[:actions])
          Macros.session_macros << macro
          Macros.recording[edit_view] = nil
          Macros.last_run_or_recorded = macro
        else
          h = edit_view.history.subscribe do |action|
            Macros.recording[edit_view][:actions] << action
          end
          Macros.recording[edit_view] = {:subscriber => h, :actions => []}
        end
        Redcar.app.repeat_event(:macro_record_changed)
      end
    end
    
    class RunLastCommand < Redcar::DocumentCommand
      sensitize :not_recording_a_macro, :is_last_macro
      
      def execute
        macro = Macros.last_run_or_recorded
        macro.run_in(edit_view)
      end
    end
    
    class NameLastMacroCommand < Redcar::Command
      sensitize :any_macros_recorded_this_session
      
      def execute
        result = Application::Dialog.input("Macro Name", 
          "Assign a name to the last recorded macro:", "Nameless Macro :(")
        if result[:button] == :ok
          macro = Macros.session_macros.last
          macro.name = result[:value]
          Macros.session_macros.delete(macro)
          Macros.save_macro(macro)
          Redcar.app.repeat_event(:macro_named)
        end
      end
    end
    
    class ShowMacrosCommand < Redcar::Command
      def execute
        Macros.session_macros.each do |macro|
          puts "#{macro.name}: "
          macro.actions.each do |action|
            puts "  * #{action.inspect}"
          end
        end
      end
    end
  end
end