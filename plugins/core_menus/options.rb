
module Redcar::Plugins::CoreMenus
  module OptionsMenu
    extend Redcar::CommandBuilder
    extend Redcar::MenuBuilder
    
    command "Core/Options/Preferences" do |c|
      c.menu = "Options/Preferences"
      c.icon = :PREFERENCES
      c.command %q{ Redcar::PreferencesDialog.new.run }
    end
    
  end
end
