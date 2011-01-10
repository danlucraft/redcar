require 'ruby/syntax_checker'
require 'ruby/repl_mirror'

module Redcar
  class Ruby

    def self.menus
      Menu::Builder.build do
        sub_menu "Plugins" do
          sub_menu "REPL" do
            item "Open Ruby REPL", RubyOpenREPL
          end
        end
      end
    end

    def self.keymaps
      osx = Keymap.build("main", :osx) do
        link "Cmd+Shift+R", RubyOpenREPL
      end

      linwin = Keymap.build("main", [:linux, :windows]) do
        link "Ctrl+Shift+R", RubyOpenREPL
      end

      [linwin, osx]
    end

    class RubyOpenREPL < Redcar::REPL::OpenREPL
      def execute
        open_repl(ReplMirror.new)
      end
    end
  end
end
