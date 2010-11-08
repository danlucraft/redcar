require 'web_bookmarks/commands'
require 'web_bookmarks/bookmark'
require 'web_bookmarks/tree'

module Redcar
  class WebBookmarks
    TREE_TITLE = "Web Bookmarks"
    BOOKMARKS_FILE = "web_bookmarks.json"

    def self.storage
      @storage ||= begin
         storage = Plugin::Storage.new('web_bookmarks')
         storage.set_default('show_browser_bar_on_start', true)
         storage
      end
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
