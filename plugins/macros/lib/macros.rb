
require 'macros/action_sequence'
require 'macros/commands'
require 'macros/macro'
require 'macros/manager_controller'

require 'macros/predictive/sequence_finder'
require 'macros/predictive/document_controller'

module Redcar
  module Macros
    DONT_RECORD_COMMANDS = [StartStopRecordingCommand, RunLastCommand, NameLastMacroCommand]

    def self.recording
      @recording ||= {}
    end

    def self.session_macros
      @session_macros ||= []
    end

    def self.saved_macros
      @saved_macros ||= storage['saved_macros']
    end

    def self.save_macro(macro)
      saved_macros << macro
      update_storage
    end

    def self.update_storage
      storage['saved_macros'] = saved_macros
    end

    class << self
      attr_accessor :last_run
      attr_accessor :last_run_or_recorded
    end

    def self.storage
      @storage ||= begin
        storage = Plugin::Storage.new('macros')
        storage.set_default('saved_macros', [])
        storage
      end
    end

    def self.name_macro(macro_name, msg)
      if macro = Macros.session_macros.detect {|m| m.name == macro_name }
        result = Application::Dialog.input("Macro Name",
              msg, macro.name)
        if result[:button] == :ok
          macro.name = result[:value]
          Macros.session_macros.delete(macro)
          Macros.save_macro(macro)
          Redcar.app.repeat_event(:macro_named)
        end
      end
    end

    def self.rename_macro(macro_name)
      if macro = Macros.saved_macros.detect {|m| m.name == macro_name }
        result = Application::Dialog.input("Macro Name",
              "Rename macro:", macro.name)
        if result[:button] == :ok
          macro.name = result[:value]
          update_storage
          Redcar.app.repeat_event(:macro_named)
        end
      end
    end

    def self.delete_macro(macro_name)
      if macro = Macros.saved_macros.detect {|m| m.name == macro_name }
        Macros.saved_macros.delete(macro)
        update_storage
      elsif macro = Macros.session_macros.detect {|m| m.name == macro_name }
        Macros.session_macros.delete(macro)
      end
    end

    def self.menus
      Menu::Builder.build do
        sub_menu "Plugins" do
          sub_menu "Macros" do
            item proc {
                if Macros.recording[EditView.focussed_edit_view]
                  "Stop Recording"
                else
                  "Start Recording"
                end
              }, StartStopRecordingCommand
            item "Run Last", RunLastCommand
            item "Name and Save Last Recorded", NameLastMacroCommand
            separator
            item "Macro Manager", MacroManagerCommand
            lazy_sub_menu "New" do
              Macros.session_macros.reverse.each do |macro|
                item(macro.name) { macro.run }
              end
            end
            lazy_sub_menu "Saved" do
              Macros.saved_macros.reverse.each do |macro|
                item(macro.name) { macro.run }
              end
            end
            separator
            item "Predict", PredictCommand
            item "Change Prediction", AlternatePredictCommand
          end
        end
      end
    end

    def self.keymaps
      osx = Redcar::Keymap.build("main", :osx) do
        link "Cmd+Alt+M", StartStopRecordingCommand
        link "Cmd+Shift+M", RunLastCommand
        link "Cmd+Alt+Shift+M", NameLastMacroCommand
        link "Cmd+P", PredictCommand
        link "Cmd+Alt+P", AlternatePredictCommand
      end

      linwin = Redcar::Keymap.build("main", [:linux, :windows]) do
        link "Ctrl+Alt+M", StartStopRecordingCommand
        link "Ctrl+Shift+M", RunLastCommand
        link "Ctrl+Alt+Shift+M", NameLastMacroCommand
        link "Ctrl+P", PredictCommand
        link "Ctrl+Alt+P", AlternatePredictCommand
      end
      [osx, linwin]
    end

    def self.document_controller_types
      [Macros::Predictive::DocumentController]
    end

    def self.sensitivities
      [
        Sensitivity.new(:not_recording_a_macro, Redcar.app, false, [:tab_focussed, :macro_record_changed]) do
          edit_view = EditView.focussed_edit_view
          !edit_view or !Macros.recording[edit_view]
        end,
        Sensitivity.new(:recording_a_macro, Redcar.app, false, [:tab_focussed, :macro_record_changed]) do
          edit_view = EditView.focussed_edit_view
          edit_view and Macros.recording[edit_view]
        end,
        Sensitivity.new(:is_last_macro, Redcar.app, false, [:macro_record_changed, :macro_ran]) do
          Macros.last_run_or_recorded
        end,
        Sensitivity.new(:any_macros_recorded_this_session, Redcar.app, false, [:macro_record_changed, :macro_named]) do
          Macros.session_macros.any?
        end,
        Sensitivity.new(:in_prediction_mode, Redcar.app, false, [:tab_focussed, :start_prediction_mode, :end_prediction_mode]) do
          edit_view = EditView.focussed_edit_view
          if edit_view
            if controller = edit_view.document.controllers(Macros::Predictive::DocumentController).first
              controller.in_prediction_mode?
            end
          end
        end
      ]
    end
  end
end


