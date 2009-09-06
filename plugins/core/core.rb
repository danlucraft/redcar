
module Redcar
  class Core
    def self.load(plugin)
      require lib("plugin")
      plugin.transition(FreeBASE::LOADED)
    end

    def self.start(plugin)
      plugin.transition(FreeBASE::RUNNING)
    end
    
    private
    
    def self.lib(name)
      File.expand_path(File.join(File.dirname(__FILE__), "lib", name))
    end
  end
end
