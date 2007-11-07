
require File.dirname(__FILE__) + '/sourceview'

module Redcar
  module Plugins
    module SyntaxView
      extend FreeBASE::StandardPlugin
      extend Redcar::PreferencesBuilder
      
      preference "Appearance/Tab Theme" do |p|
        p.type = :combo
        p.default = "Mac Classic"
        p.values = fn { Theme.theme_names }
        p.change do 
          Redcar.current_window.all_tabs.each do |tab|
            if tab.respond_to? :sourceview
              tab.sourceview.set_theme(Theme.theme(TextTab::Preferences["Tab Theme"]))
            end
          end
        end
      end
      
      preference "Appearance/Entry Theme" do |p|
        p.type = :combo
        p.default = "Mac Classic"
        p.values = fn { Theme.theme_names }
      end
    
      def self.load(plugin)
        Redcar::SyntaxSourceView.init(:bundles_dir => "textmate/Bundles/",
                                      :themes_dir  => "textmate/Themes/",
                                      :cache_dir   => "cache/")
        plugin.transition(FreeBASE::LOADED)
      end
    end
  end
end
