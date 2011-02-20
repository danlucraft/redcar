
# $:.push(File.expand_path(File.join(File.dirname(__FILE__),
#   "vendor", "activesupport-3.0.3", "lib")))
#
# require 'active_support'
# require 'active_support/inflections'
module Redcar
  # This class is your plugin. Try adding new commands in here
  # and putting them in the menus.
  class KeyBindings
    
    def self.user_keybindings
      puts "binding Cmd Shift U"
      {"Cmd+Shift+U" => Redcar::RunTestCommand }
      
    end
        
  end
end