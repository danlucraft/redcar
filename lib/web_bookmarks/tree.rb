
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
        groups = {}
        bookmarks_files_paths.each do |path|
          json = File.read(path)
          bookmarks += JSON(json)["bookmarks"]
        end

        if bookmarks.any?
          bookmarks.sort_by {|b| b["name"]}.map do |b|
            if groups[b["group"]]
              group = groups[b["group"]]
            else
              group = Bookmark.new(b["group"],nil)
              groups[group.text] = group
            end
            prefix = b["protocol"] || "http"
            url = prefix + "://" + parse_url(b["url"])
            group.add(Bookmark.new(b["name"],url))
          end
          groups.sort_by {|k,g| k}.map {|k,g| g}
        else
          []
        end
      end
    end
  end
end
