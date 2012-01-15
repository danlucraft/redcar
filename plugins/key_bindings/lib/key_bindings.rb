
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
      key_bindings = key_binding_prefs.inject({}) do |h, (key, command_class)|
        begin
          h[key] = eval(command_class)
        rescue
          warn "WARNING: invalid key binding from \"#{key}\" to #{command_class.inspect} in file \"#{@storage.send(:path)}\""
        end
        h
      end
      key_bindings
    end
    
    def self.storage
      @storage ||= Plugin::Storage.new('key_bindings')
    end
    
    def self.key_binding_prefs
      storage["key_bindings"] ||= {}
    end
    
    def self.add_key_binding(key, command)
      key_binding_prefs[key] = command
      storage.save
      Redcar.app.refresh_menu!
    end
  end
end
