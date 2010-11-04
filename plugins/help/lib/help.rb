
module Redcar
  class Help
    def self.menus
      Redcar::Menu::Builder.build do
        sub_menu "Help" do
          group(:priority => :first) do
            item "Online Help", :command => OnlineHelpCommand
            item "Submit a Bug", :command => SubmitABugCommand
          end
        end
      end
    end

    def self.keymaps
      map = Redcar::Keymap.build("main", [:osx, :linux, :windows]) do
        link "F1", OnlineHelpCommand
      end
      [map]
    end

    class SubmitABugCommand < Redcar::Command
      def execute
        if OpenDefaultBrowserCommand.supported?
          OpenDefaultBrowserCommand.new("https://redcar.lighthouseapp.com/projects/25090-redcar/tickets/new").run
        else
          Redcar::WebBookmarks::DisplayWebContent.new(
          "Submit a Bug",
          "https://redcar.lighthouseapp.com/projects/25090-redcar/tickets/new"
          ).run
        end
      end
    end

    class OnlineHelpCommand < Redcar::Command
      def execute
        if OpenDefaultBrowserCommand.supported?
          OpenDefaultBrowserCommand.new("http://github.com/redcar/redcar/wiki/Users-Guide").run
        else
          Redcar::WebBookmarks::DisplayWebContent.new(
          "Online Help",
          "http://github.com/redcar/redcar/wiki/Users-Guide"
          ).run
        end
      end
    end
  end
end