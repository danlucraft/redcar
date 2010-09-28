require 'web_bookmarks/commands'
require 'web_bookmarks/bookmark'
require 'web_bookmarks/tree'
require 'web_bookmarks/view_controller'

module Redcar
  class WebBookmarks
    TREE_TITLE = "Web Bookmarks"

    def self.display_content(name,url)
      win = Redcar.app.focussed_window
      controller = ViewController.new(name,url)
      tab = win.new_tab(HtmlTab)
      tab.html_view.controller = controller
      tab.focus
    end

    def self.menus
      Redcar::Menu::Builder.build do
        sub_menu "Project" do
          item "Web Bookmarks", :command => WebBookmarks::ShowTree, :priority => 40
        end
      end
    end

    def self.toolbars
      Redcar::ToolBar::Builder.build do
        item "Web Bookmarks", :command => WebBookmarks::ShowTree, :icon => File.join(Redcar::ICONS_DIRECTORY, "globe.png"), :barname => :project
      end
    end
  end
end
