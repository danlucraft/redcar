
module Redcar
  class WebBookmarks
     class Bookmark
      include Redcar::Tree::Mirror::NodeMirror
      attr_reader :url

      def initialize(name,url)
        @name = name
        @url = url
      end

      def leaf?
        true
      end

      def text
        @name
      end

      def icon
        if @url =~ /^file/
          File.join(Redcar::ICONS_DIRECTORY, "document-globe.png")
        else
          File.join(Redcar::ICONS_DIRECTORY, "globe.png")
        end
      end

      def children
        []
      end
    end
  end
end