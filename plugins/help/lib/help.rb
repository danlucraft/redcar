
require 'help/view_controller'
require 'help/help_tab'

module Redcar
  class Help
    def self.menus
      Redcar::Menu::Builder.build do
        sub_menu "Help" do
          group(:priority => :first) do
            item "Online Help", :command => OnlineHelpCommand
            item "Submit a Bug", :command => SubmitABugCommand
            item "Keyboard Shortcuts", :command => ViewShortcutsCommand
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

    def self.toolbars
      ToolBar::Builder.build do
        item "Keyboard Shortcuts", :command => ViewShortcutsCommand, :icon => File.join(Redcar.icons_directory, "/keyboard.png"), :barname => :help
        item "Help", :command => OnlineHelpCommand, :icon => File.join(Redcar.icons_directory, "/question.png"), :barname => :help
      end
    end

    class ViewShortcutsCommand < Redcar::Command
      def execute
        controller = Help::ViewController.new
        tab = win.new_tab(Help::HelpTab)
        tab.html_view.controller = controller
        tab.focus
      end
    end

    class SubmitABugCommand < Redcar::Command
      def execute
        Redcar::HtmlView::DisplayWebContent.new(
          "Submit a Bug",
          "https://redcar.lighthouseapp.com/projects/25090-redcar/tickets/new",
          true,
          Help::HelpTab
        ).run
      end
    end

    class OnlineHelpCommand < Redcar::Command
      def execute
        Redcar::HtmlView::DisplayWebContent.new(
          "Online Help",
          "http://github.com/redcar/redcar/wiki/Users-Guide",
          true,
          Help::HelpTab
        ).run
      end
    end
  end
end