require 'test_runner/runnable_test_runner'
require 'test_runner/jasmine_test_runner'
require 'test_runner/rspec_runner'
require 'test_runner/run_test_command'
#
# $:.push(File.expand_path(File.join(File.dirname(__FILE__),
#   "vendor", "activesupport-3.0.3", "lib")))
#
# require 'active_support'
# require 'active_support/inflections'
module Redcar
  # This class is your plugin. Try adding new commands in here
  # and putting them in the menus.
  class TestRunner
  
    # This method is run as Redcar is booting up.
    def self.menus
      # Here's how the plugin menus are drawn. Try adding more
      # items or sub_menus.
      Menu::Builder.build do
        sub_menu "Plugins" do
          sub_menu "Test Runner", :priority => 139 do
            item "Run Test", RunTestCommand
          end
        end
      end
    end

    def self.keymaps
      osx = Redcar::Keymap.build("main", :osx) do
        link "Cmd+Alt+T", RunTestCommand
      end
      linwin = Redcar::Keymap.build("main", [:linux, :windows]) do
        link "Ctrl+Alt+T", RunTestCommand
      end
      [osx, linwin]
    end
    
  end
end