
module Redcar
  class Project
    class DirController
      def activated(node)
        if node.leaf?
          FileOpenCommand.new(node.path).run
        end
      end
      
      def right_click(node)
        p [:dir_controller, :right_click, node]
      end
    end
  end
end

    