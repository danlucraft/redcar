
module Redcar
  class WebBookmarks
    class BookmarkReloadItem
      include Redcar::Tree::Mirror::NodeMirror
      
      def leaf?; true; end
      def text; "Reload Bookmarks"; end
      def icon; :"arrow_circle"; end
      def children; []; end
    end
    
    class Bookmark
      include Redcar::Tree::Mirror::NodeMirror
      attr_reader :url

      def initialize(name,url)
        @name = name
        @url = url
        @children = []
      end

      def leaf?
        children.length < 1
      end

      def add(bookmark)
        @children << bookmark
      end

      def text
        @name
      end

      def icon
        if leaf?
          if @url =~ /^file/
            File.join(Redcar.icons_directory, "document-globe.png")
          else
            File.join(Redcar.icons_directory, "globe.png")
          end
        else
          File.join(Redcar.icons_directory, "book-bookmark.png")
        end
      end

      def children
        @children
      end
    end
  end
end