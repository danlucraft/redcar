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
          item "Web Bookmarks", :command => WebBookmarks::ShowWebBookmarksCommand, :priority => 40
        end
      end
    end

     def self.keymaps
      osx = Keymap.build("main", :osx) do
        link "Cmd+Shift+?", WebBookmarks::ShowWebBookmarksCommand
      end
      lin = Keymap.build("main", [:linux,:windows]) do
        link "Ctrl+Shift+?", WebBookmarks::ShowWebBookmarksCommand
      end
      [osx,lin]
    end

    def self.toolbars
      Redcar::ToolBar::Builder.build do
        item "Web Bookmarks", :command => WebBookmarks::ShowWebBookmarksCommand, :icon => File.join(Redcar.icons_directory, "globe.png"), :barname => :project
      end
    end

    def self.project_closed(project,window)
      wtree = window.treebook.trees.detect { |t|
        t.tree_mirror.is_a? WebBookmarks::TreeMirror
      }
      wtree.close if wtree
    end
  end
end
