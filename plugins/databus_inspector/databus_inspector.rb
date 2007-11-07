
require File.dirname(__FILE__) + '/databus_tab'

module Redcar
  module Plugins
    module DatabusInspector
      extend FreeBASE::StandardPlugin
      extend Redcar::CommandBuilder
      extend Redcar::MenuBuilder
      
      command "Databus Inspector/Open" do |c|
        c.menu = "Tools/Databus Inspector"
        c.icon = :PREFERENCES
        c.command =<<-RUBY
          new_tab = Redcar.new_tab(Redcar::DatabusTab)
          new_tab.focus
          new_tab.name = "Databus Inspector"
          Redcar.StatusBar.main = "Opened Databus Inspector"
        RUBY
      end
    end
  end
end
