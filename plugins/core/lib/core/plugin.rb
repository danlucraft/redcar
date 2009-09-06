
module Redcar
  class Plugin
    def self.load(plugin)
      on_load if respond_to?(:on_load)
      plugin.transition(FreeBASE::LOADED)
    end
    
    def self.start(plugin)
      on_start if respond_to?(:on_start)
      plugin.transition(FreeBASE::RUNNING)
    end
  end
end