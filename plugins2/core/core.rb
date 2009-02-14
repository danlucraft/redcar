
# load 'lib/app.rb'
# load 'lib/command.rb'
# load 'lib/dialog.rb'
# load 'lib/document.rb'

load File.dirname(__FILE__) + '/lib/preference.rb'
load File.dirname(__FILE__) + '/lib/menu.rb'
load File.dirname(__FILE__) + '/lib/sensitive.rb'
load File.dirname(__FILE__) + '/lib/keymap.rb'
load File.dirname(__FILE__) + '/lib/command.rb'

Dir[File.dirname(__FILE__) + "/lib/*"].each {|fn| load fn}

module Redcar
  class CorePlugin < Redcar::Plugin
    def self.load(plugin) # :nodoc:
      App.load
      Window.load
      Tooltip.load
      Menu.load
      Preference.load
      Tab.load
      Gui.load
      Command.load
      Keymap.load
      Bundle.load
      plugin.transition(FreeBASE::LOADED)
    end

    def self.start(plugin)
      Menu.start
      Tab.start
      Gui.start
      Command.start
      plugin.transition(FreeBASE::RUNNING)
    end

    def self.stop(plugin)
      Menu.stop
      Tab.stop
      Command.stop
      Window.stop
      plugin.transition(FreeBASE::LOADED)
    end
  end
end

load File.dirname(__FILE__) + '/commands/tab_command.rb'
Dir[File.dirname(__FILE__) + "/commands/*"].each {|fn| load fn}
