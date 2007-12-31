
require 'gnomevfs'

module Redcar
  module Plugins
    module Scripting
      extend FreeBASE::StandardPlugin
      extend Redcar::PreferencesBuilder
      extend Redcar::MenuBuilder
      extend Redcar::CommandBuilder
      
      def self.load(plugin)
        plugin.transition(FreeBASE::LOADED)
      end
    end
  end
end
