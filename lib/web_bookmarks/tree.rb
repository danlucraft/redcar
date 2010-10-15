
module Redcar
  class WebBookmarks
    class TreeController
      include Redcar::Tree::Controller

      def initialize(project)
        @project = project
      end

      def activated(tree, node)
        DisplayWebContent.new(node.text,node.url).run
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
        spares = []
        groups = {}
        bookmarks_files_paths.each do |path|
          json = File.read(path)
          bookmarks += JSON(json)["bookmarks"]
        end

        if bookmarks.any?
          bookmarks.sort_by {|b| b["name"]}.map do |b|
            prefix = b["protocol"] || "http"
            url = prefix + "://" + parse_url(b["url"])
            if b["group"].nil?
              spares << Bookmark.new(b["name"],url)
            else
              if groups[b["group"]]
                group = groups[b["group"]]
              else
                group = Bookmark.new(b["group"],nil)
                groups[group.text] = group
              end
              group.add(Bookmark.new(b["name"],url))
            end
          end
          spares.sort_by {|s| s.text} + groups.sort_by {|k,g| k}.map {|k,g| g}
        else
          []
        end
      end
    end
  end
end
