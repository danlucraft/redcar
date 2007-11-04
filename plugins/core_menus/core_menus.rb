
module Redcar
  module Plugins
    module CoreMenus
      extend FreeBASE::StandardPlugin
      
      def self.load(plugin)
        plugin.transition(FreeBASE::LOADED)
      end
      
      def self.start(plugin)
        plugin.transition(FreeBASE::RUNNING)
      end
    end
  end
end
