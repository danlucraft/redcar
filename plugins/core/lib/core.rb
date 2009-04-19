
$:.push(File.dirname(__FILE__))

load 'core/preference.rb'
load 'core/menu.rb'
load 'core/sensitive.rb'
load 'core/keymap.rb'
load 'core/command_activation.rb'
load 'core/executor.rb'
load 'core/command.rb'
load 'core/plugin.rb'
load 'core/tab.rb'
load 'core/range.rb'
load 'core/window.rb'
load 'core/app.rb'
load 'core/hook.rb'
load 'core/tooltip.rb'
load 'core/bundles.rb'
load 'core/gui.rb'
load 'core/speedbar.rb'
load 'core/shell_command.rb'
load 'core/pane.rb'
load 'core/template.rb'
load 'core/command_history.rb'
load 'core/dialog.rb'
load 'core/dbus.rb'

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
      Hook.attach(:redcar_start) do
        puts "redcar_start: #{Time.now - Redcar::PROCESS_START_TIME} seconds"
      end
      unless Redcar::App.ARGV.include?("--multiple-instance")
        Redcar::DBus.start_listener
      end
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

load File.dirname(__FILE__) + '/../commands/tab_command.rb'
Dir[File.dirname(__FILE__) + "/../commands/*"].each {|fn| load fn}
