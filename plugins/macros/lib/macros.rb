require 'macros/commands'
require 'macros/macro'

module Redcar
  module Macros
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
            item "Start/Stop Recording", StartStopRecordingCommand
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
  end
end