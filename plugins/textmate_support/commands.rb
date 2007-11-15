
module Redcar::Plugins
  module Textmate
    module Commands
      extend FreeBASE::StandardPlugin
      
      def start(plugin)
        load_menu
        plugin.transition(FreeBASE::RUNNING)
      end
      
      def load_menu
        
      end
    end
  end
end
