
require 'gtkmozembed'

module Redcar
  class HtmlTabPlugin < Redcar::Plugin
    
    def self.load(plugin) #:nodoc:
      Kernel.load File.dirname(__FILE__) + "/tabs/html_tab.rb"
      Kernel.load File.dirname(__FILE__) + "/commands/open_html_tab_command.rb"
      plugin.transition(FreeBASE::LOADED)
    end
    
  end
end
