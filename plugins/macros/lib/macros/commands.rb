
module Redcar
  module Macros
    class StartStopRecordingCommand < Redcar::EditTabCommand
      def self.unique_session_id
        @unique_id ||= 0
        @unique_id += 1
        @unique_id
      end
      
      def execute
        if info = Macros.recording[edit_view]
          edit_view.history.unsubscribe(info[:subscriber])
          if info[:actions].any?
            macro = Macro.new("Nameless Macro #{StartStopRecordingCommand.unique_session_id} :(", info[:actions])
            Macros.session_macros << macro
            Macros.last_run_or_recorded = macro
          end
          Macros.recording[edit_view] = nil
        else
          ev = edit_view
          h = ev.history.subscribe do |action|
            Macros.recording[ev][:actions] << action
          end
          Macros.recording[ev] = {:subscriber => h, :actions => []}
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
        Macros.name_macro(Macros.session_macros.last.name, 
          "Assign a name to the last recorded macro:")
      end
    end
    
    class MacroManagerCommand < Redcar::Command
      def execute
        controller = ManagerController.new
        tab = win.new_tab(HtmlTab)
        tab.html_view.controller = controller
        tab.focus
      end
    end
  end
end