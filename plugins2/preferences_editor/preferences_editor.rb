
require File.dirname(__FILE__) + '/preferences_dialog'

module Com::RedcarIDE
  class PreferencesEditor < Redcar::Plugin
    
    class OpenPreferencesDialog < Redcar::Command
      menu "Options/Preferences"
      icon :PREFERENCES
      def execute
        PreferencesDialog.new.run
      end
    end
  end
end
