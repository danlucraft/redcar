
module Redcar
  class Keymap
    def initialize(name)
      @name = name
      @map  = {}
    end
    
    def link(key_string, command)
      @map[key_string] = command
    end
    
    def command(key_string)
      @map[key_string]
    end
    
    def command_to_key(command)
      @map.invert[command]
    end
    
    def length
      @map.length
    end
  end
end
 