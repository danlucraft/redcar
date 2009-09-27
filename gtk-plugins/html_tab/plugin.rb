
$:.push(File.expand_path(File.dirname(__FILE__) + "/../../vendor/rbwebkitgtk/src"))
require 'lib/webkit'

module Redcar
  class HtmlTabPlugin < Redcar::Plugin
    
    def self.load(plugin) #:nodoc:
      Kernel.load File.dirname(__FILE__) + "/tabs/html_tab.rb"
      plugin.transition(FreeBASE::LOADED)
    end
    
  end
end
