
require File.dirname(__FILE__) + '/command_inspector_tab'

module Redcar
  module Plugins
    module CommandInspector
      extend FreeBASE::StandardPlugin
      extend Redcar::CommandBuilder
      extend Redcar::MenuBuilder
      
      command "Command Inspector/Open" do |c|
        c.menu = "Tools/Command Inspector"
        c.icon = :PREFERENCES
        c.command =<<-RUBY
          new_tab = Redcar.new_tab(Redcar::CommandInspectorTab)
          new_tab.name = "Command Inspector"
          new_tab.focus
          Redcar.StatusBar.main = "Opened Command Inspector"
        RUBY
      end
    end
  end
end
