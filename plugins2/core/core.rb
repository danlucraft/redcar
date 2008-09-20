
# load 'lib/app.rb'
# load 'lib/command.rb'
# load 'lib/dialog.rb'
# load 'lib/document.rb'
load File.dirname(__FILE__) + '/lib/sensitive.rb'

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
      plugin.transition(FreeBASE::LOADED)
    end

    def self.start(plugin)
      Menu.start
      Tab.start
      Gui.start
      Command.start
      Window.start
      Keymap.start
      plugin.transition(FreeBASE::RUNNING)
    end

    def self.stop(plugin)
      Menu.stop
      Tab.stop
      Command.stop
      Window.stop
      Keymap.stop
      plugin.transition(FreeBASE::LOADED)
    end
  end
end
