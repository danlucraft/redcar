
module Redcar
  class Runnables
    class AppendParamsAndRunCommand < Redcar::Command
      def initialize(node)
        @node = node
      end

      def execute
        command = @node.command
        command = "#{command} #{PARAMS}" unless command =~ /#{PARAMS}$/
        Runnables.run_process(@node.path, command, @node.text, @node.output)
      end
    end

    class ShowRunnables < Redcar::Command
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
            path = tab.edit_view.document.mirror.path
            command = command_schema.gsub("__PATH__", path)
            Runnables.run_process(project.home_dir,command, "Running #{File.basename(path)}", output)
          end
        end
      end
    end
  end
end