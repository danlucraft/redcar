module Redcar
  class Runnables
    class RunnableTypeGroup
      include Redcar::Tree::Mirror::NodeMirror

      def initialize(name,path,runnables)
        @name = name
        if runnables.any?
          @children = runnables.map do |runnable|
            Runnable.new(runnable["name"],path,runnable)
          end
        end
      end

      def leaf?
        false
      end

      def text
        @name
      end

      def icon
        File.join(Redcar::ICONS_DIRECTORY, "folder-open-small-gears.png")
      end

      def children
        @children
      end
    end
  end
end