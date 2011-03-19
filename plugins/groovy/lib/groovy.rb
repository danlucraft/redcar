
require 'groovy/commands'
require 'groovy/repl_mirror'
require 'groovy/syntax_checker'

module Redcar
  class Groovy

    def self.load_dependencies
      unless @loaded
        require File.join(Redcar.asset_dir,"groovy-all")
        @loaded = true
      end
    end

    def self.menus
      Redcar::Menu::Builder.build do
        sub_menu "Plugins" do
          sub_menu "REPL" do
            item "Open Groovy REPL", OpenGroovyREPL
          end
        end
      end
    end

    def self.keymaps
      osx = Keymap.build("main", :osx) do
        link "Cmd+Alt+G", OpenGroovyREPL
      end

      linwin = Keymap.build("main", [:linux, :windows]) do
        link "Ctrl+Alt+G", OpenGroovyREPL
      end

      [linwin, osx]
    end
  end
end