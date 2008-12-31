
require 'gtkmozembed'

module Redcar
  class HtmlTabPlugin < Redcar::Plugin
    
    def self.load(plugin) #:nodoc:
      Kernel.load File.dirname(__FILE__) + "/tabs/html_tab.rb"
      plugin.transition(FreeBASE::LOADED)
    end
    
  end
end
