
#require 'gnomevfs'

module Redcar
  module Plugins
    module Scripting
      extend FreeBASE::StandardPlugin
      extend Redcar::PreferencesBuilder
      extend Redcar::MenuBuilder
      extend Redcar::CommandBuilder
      
      STARTUP_SCRIPT = File.expand_path("~/.Redcar/startup.rb")
      
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
        $BUS["/system/state/all_plugins_loaded"].subscribe do |event, slot|
          if $BUS["/system/state/all_plugins_loaded"].data.to_bool
            run_startup_script
          end
        end
        plugin.transition(FreeBASE::LOADED)
      end
    end
  end
end
