
module Redcar
  module Scm
    class ToggleScmTree < Command
      sensitize :open_scm
      
      def execute(options)
        raise "ToggleScmTree requires a class value." if not options[:value]
        
        command = options[:value][0]
        klass = options[:value][1]
        project = Project::Manager.focussed_project
        info = Scm::Manager.project_repositories[project]
        tree = info['trees'].find {|t| t.tree_mirror.is_a?(klass[0])}
        
        if tree
          info['trees'].delete tree
          focussed = project.window.treebook.focussed_tree == tree
          project.window.treebook.remove_tree(tree)
          
          # return focus to the project module if we were currently focussed
          project.window.treebook.focus_tree(project.tree) if focussed
        elsif info['repo'].supported_commands.include? command
          mirror = klass[0].new(info['repo'])
          tree = Tree.new(mirror, klass[1].new(info['repo']))
          project.window.treebook.add_tree(tree)
          tree.tree_mirror.top.each {|n| tree.expand(n)}
          info['trees'].push tree
        else
          Application::Dialog.message_box("Sorry, but your SCM doesn't support this tree.")
        end
      end
    end
  end
end
