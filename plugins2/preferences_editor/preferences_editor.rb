
require File.dirname(__FILE__) + '/preferences_dialog'

module Com::RedcarIDE
  class PreferencesEditor < Redcar::Plugin
    
    user_commands do
      def self.open_preferences_dialog
        PreferencesDialog.new.run
      end
    end
    
    main_menu "Options" do
      item "Preferences", :open_preferences_dialog, :icon => :PREFERENCES
    end
  end
  
end
