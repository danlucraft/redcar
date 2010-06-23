
module Redcar
  class Runnables
    
    class TreeMirror
      include Redcar::Tree::Mirror
      
      def initialize(project)
        runnables = project.config_file(:runnables)
        if runnables
          @top = runnables.map do |name, info|
            Runnable.new(name, info)
          end
        else
          @top = [HelpItem.new]
        end
      end
      
      def title
        "Runnables"
      end
      
      def top
        @top
      end
    end
    
    class HelpItem
      include Redcar::Tree::Mirror::NodeMirror
      
      def text
        "No runnables (HELP)"
      end
    end
    
    class Runnable
      include Redcar::Tree::Mirror::NodeMirror
      
      def initialize(name, info)
        @name = name
        @info = info
      end
      
      def text
        @name
      end
      
      def leaf?
        @info[:command]
      end
      
      def icon
        if leaf?
          File.dirname(__FILE__) + "/../icons/cog.png"
        end
      end
      
      def children
        return [] if leaf?
        
        @info.map do |name, info|
          Runnable.new(name, info)
        end
      end
      
      def command
        @info[:command]
      end
    end
    
    class TreeController
      include Redcar::Tree::Controller
      
      def initialize(project)
        @project = project
      end
      
      def activated(tree, node)
        command = node.command
        output = `#{command}`
        tab = Redcar.app.focussed_window.new_tab(EditTab)
        tab.edit_view.document.text = output
        tab.title = node.text
        tab.focus
      end
    end
    
    class ShowRunnables < Redcar::Command
      def execute
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
