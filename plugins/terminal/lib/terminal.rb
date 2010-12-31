
require 'terminal/repl_mirror'

module Redcar
  class Terminal

    def self.menus
      Menu::Builder.build do
        sub_menu "Plugins" do
          sub_menu "REPL" do
            item "Open Terminal", ShellOpenREPL
          end
        end
      end
    end

    class ShellOpenREPL < Redcar::REPL::OpenREPL
      def execute
        open_repl(ReplMirror.new)
      end
    end
  end
end