
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
      @storage ||= Plugin::Storage.new('key_bindings')
      key_bindings = @storage["key_bindings"].inject({}) do |h, (key, command_class)|
        h[key] = eval(command_class)
        h
      end
      key_bindings
    end
        
  end
end