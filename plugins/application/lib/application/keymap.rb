
module Redcar
  class Keymap
    def self.build(name, platform, &block)
      Builder.new(name, platform, &block).keymap
    end

    attr_reader :name, :platforms
    attr_accessor :map

    def initialize(name, platforms)
      @name, @platforms = name, [*platforms]
      @map = {}
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

    def merge(other)
      keymap = Keymap.new(@name, @platforms)
      (@map.keys & other.map.keys).each do |key|
        puts "conflicting keybinding #{key}: #{@map[key].inspect} is being overwritten by #{other.map[key].inspect}"
      end
      keymap.map = @map.merge(other.map)
      keymap
    end
  end
end
