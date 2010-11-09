
module Redcar
  module Macros
    class StartStopRecordingCommand < Redcar::EditTabCommand
      def self.unique_session_id
        @unique_id ||= 0
        @unique_id += 1
        @unique_id
      end
      
      def self.new_macro_message
        "Nameless Macro #{StartStopRecordingCommand.unique_session_id} :("
      end
      
      def execute
        clear_recordings
        if info = Macros.recording[edit_view]
          edit_view.history.unsubscribe(info[:subscriber])
          if info[:actions].any?
            macro = Macro.new(StartStopRecordingCommand.new_macro_message, 
                      info[:actions],
                      info[:start_in_block_selection_mode?])
            Macros.session_macros << macro
            Macros.last_run_or_recorded = macro
          end
          Macros.recording.delete(edit_view)
          tab.update_for_file_changes
        else
          ev = edit_view
          h = ev.history.subscribe do |action|
            if should_record_action?(action)
              Macros.recording[ev][:actions] << action
            end
          end
          Macros.recording[ev] = {
            :subscriber => h, 
            :actions => [], 
            :start_in_block_selection_mode? => ev.document.block_selection_mode?
          }
          tab.icon = :control_record
        end
        Redcar.app.repeat_event(:macro_record_changed)
      end
      
      private
      
      def should_record_action?(action)
        !action.is_a?(Redcar::Command) or action.class.record?
      end
      
      def clear_recordings
        Macros.recording.keys.each do |ev|
          unless ev.exists?
            Macros.recording.delete(ev)
          end
        end
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
        tab = win.new_tab(ConfigTab)
        tab.html_view.controller = controller
        tab.focus
      end
    end
    
    class PredictCommand < Redcar::EditTabCommand
      def execute
        controller = doc.controllers(Macros::Predictive::DocumentController).first
        controller.predict
      end
    end
    
    class AlternatePredictCommand < Redcar::EditTabCommand
      sensitize :in_prediction_mode
      
      def execute
        controller = doc.controllers(Macros::Predictive::DocumentController).first
        controller.alternate_predict
      end
    end
  end
end





