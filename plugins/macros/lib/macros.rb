require 'macros/commands'
require 'macros/macro'

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
    
    def self.menus
      Menu::Builder.build do
        sub_menu "Plugins" do
          sub_menu "Macros" do
            item lambda {
                if Macros.recording[EditView.focussed_edit_view]
                  "Stop Recording"
                else
                  "Start Recording"
                end
              }, StartStopRecordingCommand
            item "Run Last", RunLastCommand
            item "Name and Save Last Recorded", NameLastMacroCommand
            item "Show Macros", ShowMacrosCommand
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
          end
        end
      end
    end
    
    def self.keymaps
      osx = Redcar::Keymap.build("main", :osx) do
        link "Cmd+Alt+M", StartStopRecordingCommand
        link "Cmd+Shift+M", RunLastCommand
        link "Cmd+Alt+Shift+M", NameLastMacroCommand
      end
      
      linwin = Redcar::Keymap.build("main", [:linux, :windows]) do
        link "Ctrl+Alt+M", StartStopRecordingCommand
        link "Ctrl+Shift+M", RunLastCommand
        link "Ctrl+Alt+Shift+M", NameLastMacroCommand
      end
      [osx, linwin]
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
        end
      ]
    end
  end
end


