
#require 'gnomevfs'

module Redcar
  module Plugins
    module Scripting
      extend FreeBASE::StandardPlugin
#      extend Redcar::PreferencesBuilder
      extend Redcar::MenuBuilder
      extend Redcar::CommandBuilder
      
      STARTUP_SCRIPT = File.expand_path("~/.Redcar/startup.rb")
      
      UserCommands do
        icon :PREFERENCES
        key  "Global/Ctrl+B"
        def run_startup_script
          Redcar::Plugins::Scripting.run_startup_script
        end
      end
      
      UserCommands("Scripts/") do
        menu "Tools/Say Hello"
        key  "Global/Ctrl+Alt+G"
        def say_hello
          puts "Hello World!"
        end
      end
      
      MainMenu "Tools" do
        item "Run Startup Script", "run_startup_script", :icon => :PREFERENCES
        separator
        item "Say Hello!", "Scripts/say_hello"
        submenu "My First Pony!" do
          item "Say Hi There Pardner", "Scripts/say_hello"
        end
      end
      
      def self.run_startup_script
        unless Redcar::App.ARGV.include? "--nostartup"
          if File.exists?(STARTUP_SCRIPT)
            require STARTUP_SCRIPT
          else
            puts "(no startup script)"
          end
        end
      end
      
      def self.load(plugin)
        bus["/system/state/all_plugins_loaded"].subscribe do |event, slot|
          if bus["/system/state/all_plugins_loaded"].data.to_bool
            run_startup_script
          end
        end
        plugin.transition(FreeBASE::LOADED)
      end
    end
  end
end
