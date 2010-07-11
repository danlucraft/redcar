
require File.dirname(__FILE__) + "/../vendor/session-2.4.0/lib/session"
Session.use_open4 = true

require 'runnables/command_output_controller'
require 'runnables/running_process_checker'

module Redcar
  class Runnables
    TREE_TITLE = "Runnables"
    
    def self.run_process(command)
      tab = Redcar.app.focussed_window.new_tab(HtmlTab)
      controller = CommandOutputController.new(command)
      tab.html_view.controller = controller
      tab.focus
    end
    
    class TreeMirror
      include Redcar::Tree::Mirror
      
      def initialize(project)
        runnable_file_paths = project.config_files("runnables/*.json")
        
        runnables = []
        runnable_file_paths.each do |path|
          json = File.read(path)
          this_runnables = JSON(json)["commands"]
          runnables += this_runnables || []
        end

        if runnables.any?
          @top = runnables.map do |runnable|
            Runnable.new(runnable["name"], runnable)
          end
        else
          @top = [HelpItem.new]
        end
      end
      
      def title
        TREE_TITLE
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
        @info["command"]
      end
      
      def icon
        if leaf?
          File.dirname(__FILE__) + "/../icons/cog.png"
        else
          :directory
        end
      end
      
      def children
        []
      end
      
      def command
        @info["command"]
      end
    end
    
    class TreeController
      include Redcar::Tree::Controller
      
      def initialize(project)
        @project = project
      end
      
      def activated(tree, node)
        Runnables.run_process(node.command)
      end
    end
    
    class ShowRunnables < Redcar::Command
      def execute
        if tree = win.treebook.trees.detect {|tree| tree.tree_mirror.title == TREE_TITLE }
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
    
    class RunEditTabCommand < Redcar::EditTabCommand
      def file_mappings
        project = Project::Manager.in_window(win)
        runnable_file_paths = project.config_files("runnables/*.json")
        
        file_runners = []
        runnable_file_paths.each do |path|
          json = File.read(path)
          this_file_runners = JSON(json)["file_runners"]
          file_runners += this_file_runners || []
        end
        file_runners
      end
      
      def execute
        file_mappings.each do |file_mapping|
          regex = Regexp.new(file_mapping["regex"])
          if tab.edit_view.document.mirror.path =~ regex
            command_schema = file_mapping["command"]
            command = command_schema.gsub("__PATH__", tab.edit_view.document.mirror.path)
            puts command
            Runnables.run_process(command)
          end
        end
      end
    end
  end
end



