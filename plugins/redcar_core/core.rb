
require File.dirname(__FILE__) + '/redcar'

module Redcar
  module Plugins
    module Core
      extend FreeBASE::StandardPlugin
      
      def self.load(plugin)
        plugin.transition(FreeBASE::LOADED)
      end
      
      def self.start(plugin)
        Redcar.startup(:output => :silent)
        plugin["/system/ui/messagepump"].set_proc do
          begin
            Gtk.main
          rescue
            p $!
          ensure
            plugin["/system/shutdown"].call(1)
          end
        end
        plugin.transition(FreeBASE::RUNNING)
      end
    end
  end
end
