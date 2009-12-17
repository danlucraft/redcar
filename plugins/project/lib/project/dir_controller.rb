
module Redcar
  class Project
    class DirController
      def activated(node)
        if node.leaf?
          FileOpenCommand.new(node.path).run
        end
      end
    end
  end
end

    