module Redcar
  class WebBookmarks
    class ShowTree < Redcar::Command
      sensitize :open_project
      def execute
        if tree = win.treebook.trees.detect {|tree| tree.tree_mirror.title == TREE_TITLE }
          tree.refresh
          win.treebook.focus_tree(tree)
        else
          project = Project::Manager.in_window(win)
          tree = Tree.new(
            TreeMirror.new(project),
            TreeController.new(project)
          )
          win.treebook.add_tree(tree)
        end
      end
    end
  end
end