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
      
    def self.menus
      Menu::Builder.build do
        sub_menu "Plugins" do
          sub_menu "Macros" do
            item "Start/Stop Recording", StartStopRecordingCommand
            item "Run Last", RunLastCommand
          end
        end
      end
    end
    
    def self.keymaps
      osx = Redcar::Keymap.build("main", :osx) do
        link "Cmd+Alt+M", StartStopRecordingCommand
        link "Cmd+Shift+M", RunLastCommand
      end
      linwin = Redcar::Keymap.build("main", [:linux, :windows]) do
        link "Ctrl+Alt+M", StartStopRecordingCommand
        link "Ctrl+Shift+M", RunLastCommand
      end
      [osx, linwin]
    end
  end
end