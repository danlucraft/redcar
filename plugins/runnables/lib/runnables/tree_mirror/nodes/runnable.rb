module Redcar
  class Runnables

    class HelpItem
      include Redcar::Tree::Mirror::NodeMirror

      def text
        "No runnables (HELP)"
      end
    end

    class Runnable
      include Redcar::Tree::Mirror::NodeMirror

      def initialize(name,path,info)
        @name = name
        @info = info
        @path = path
      end

      def text
        @name
      end

      def path
        @path
      end

      def tooltip_text
        @info["description"] || ""
      end

      def leaf?
        @info["command"]
      end

      def icon
        File.join(Redcar.icons_directory, "cog.png")
      end

      def children
        []
      end

      def command
        @info["command"]
      end

      def out?
        @info["output"]
      end

      def output
        if out?
          @info["output"]
        else
          "tab"
        end
      end
    end
  end
end