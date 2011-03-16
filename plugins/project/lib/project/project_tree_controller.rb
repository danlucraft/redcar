
module Redcar
  class Project
    class ProjectTreeController
      include Redcar::Tree::Controller

      def initialize(project,title)
        @project = project
        @title   = title
        attach_project_listener(@project.window)
      end

      def attach_project_listener(win)
        win.treebook.add_listener(:tree_removed) do |tree|
          if tree == @project.tree and r = win.treebook.trees.detect do |t|
            t.tree_mirror.title == @title
          end
            @project.close
          end
        end
      end
    end
  end
end