
require File.dirname(__FILE__) + '/sourceview'

module Redcar
  module Plugins
    module SyntaxView
      extend FreeBASE::StandardPlugin
      
      def self.load(plugin)
        # load the Themes and Syntaxes
        Redcar::SyntaxSourceView.init(:bundles_dir => "textmate/Bundles/",
                                      :themes_dir  => "textmate/Themes/",
                                      :cache_dir   => "cache/")
        plugin.transition(FreeBASE::LOADED)
      end
    end
  end
end
