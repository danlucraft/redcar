$LOAD_PATH << File.expand_path(File.dirname(__FILE__))

require "core/plugin"

module Redcar
  class Core
    extend FreeBASE::StandardPlugin
    
    def self.load(plugin)
      plugin.transition(FreeBASE::LOADED)
    end

    def self.start(plugin)
      plugin.transition(FreeBASE::RUNNING)
    end
  end
end

