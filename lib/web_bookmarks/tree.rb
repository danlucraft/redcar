
module Redcar
  class WebBookmarks
    class TreeController
      include Redcar::Tree::Controller

      def initialize(project)
        @project = project
      end

      def activated(tree, node)
        WebBookmarks.display_content(node.text,node.url)
      end
    end

    class TreeMirror
      include Redcar::Tree::Mirror

      def initialize(project)
        @project = project
      end

      def bookmarks_files_paths
         @project.config_files("web_bookmarks.json")
      end

      def parse_url(url)
        url.gsub("__PROJECT_PATH__",@project.path)
      end

      def title
        TREE_TITLE
      end

      def top
        load
      end

      def load
        bookmarks = []
        bookmarks_files_paths.each do |path|
          json = File.read(path)
          bookmarks += JSON(json)["bookmarks"]
        end

        if bookmarks.any?
          bookmarks.sort_by {|b| b["name"]}.map do |b|
            prefix = b["protocol"] || "http"
            url = prefix + "://" + parse_url(b["url"])
            Bookmark.new(b["name"],url)
          end
        else
          []
        end
      end
    end
  end
end