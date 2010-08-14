
require File.dirname(__FILE__) + "/../vendor/session/lib/session"
Session.use_open4 = true

require 'runnables/command_output_controller'
require 'runnables/running_process_checker'
require 'runnables/output_processor'

module Redcar
  class Runnables
    TREE_TITLE = "Runnables"
    
    def self.run_process(path, command, title, output)
      controller = CommandOutputController.new(path, command, title)
      if output == "window"
        Project::Manager.open_project_for_path(".")
        output = "tab"
      end
      if output == "none"
        controller.run
      else
        tab = Redcar.app.focussed_window.new_tab(HtmlTab)
        tab.html_view.controller = controller
        tab.focus
      end
    end
    
    def self.menus
      Menu::Builder.build do
        sub_menu "Project", :priority => 15 do
          group(:priority => 15) {
          separator
            item "Runnables", Runnables::ShowRunnables
            item "Run Tab",   Runnables::RunEditTabCommand
          }
        end
      end
    end
    
    class TreeMirror
      include Redcar::Tree::Mirror
      
      def initialize(project)
        runnable_file_paths = project.config_files("runnables/*.json")
        
        groups = {}
        runnable_file_paths.each do |path|
          runnables = []
          name = File.basename(path,".json")
          json = File.read(path)
          this_runnables = JSON(json)["commands"]
          runnables += this_runnables || []
          groups[name.to_s] = runnables.to_a
        end

        if groups.any?
          @top = groups.map do |name, runnables|
            RunnableGroup.new(name,runnables)
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
    
    class RunnableGroup
      include Redcar::Tree::Mirror::NodeMirror
      
      def initialize(name,runnables)
        @name = name
        if runnables.any?
          @children = runnables.map do |runnable|
            Runnable.new(runnable["name"], runnable)
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
        :file
      end
      
      def children
        @children
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
    
    class TreeController
      include Redcar::Tree::Controller
      
      def initialize(project)
        @project = project
      end
      
      def activated(tree, node)
        case node
        when Runnable
          Runnables.run_process(@project.home_dir, node.command, node.text, node.output)
        when HelpItem
          tab = Redcar.app.focussed_window.new_tab(HtmlTab)
          tab.go_to_location("http://wiki.github.com/danlucraft/redcar/users-guide-runnables")
          tab.title = "Runnables Help"
          tab.focus
        end
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
        project = Project::Manager.in_window(win)        
        file_mappings.each do |file_mapping|
          regex = Regexp.new(file_mapping["regex"])
          if tab.edit_view.document.mirror.path =~ regex
            command_schema = file_mapping["command"]
            output = file_mapping["output"]
            if output.nil?
	            output = "tab"
            end
            command = command_schema.gsub("__PATH__", tab.edit_view.document.mirror.path)
            puts command
            Runnables.run_process(project.home_dir,command, "Run File", output)
          end
        end
      end
    end
  end
end



