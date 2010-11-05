
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
              TreeController.new(project,TREE_TITLE)
            )
          win.treebook.add_tree(tree)
        end
      end
    end

    class RunEditTabCommand < Redcar::DocumentCommand
      sensitize :open_project, :focussed_committed_mirror
      def execute
        project = Project::Manager.in_window(win)
        f = Runnables.file_mappings(project).detect do |file_mapping|
          regex = Regexp.new(file_mapping["regex"])
          doc.mirror.path =~ regex
        end
        run_tab(project.home_dir,tab, f) if f
      end

      def run_tab(project_path,tab, file_mapping)
        command = file_mapping["command"]
        output = file_mapping["output"]
        path = tab.edit_view.document.mirror.path
        output = "tab" if output.nil?
        Runnables.run_process(project_path,command, "Running #{File.basename(path)}", output)
      end
    end

    class RunAlternateEditTabCommand < RunEditTabCommand
      sensitize :open_project
      def initialize
        @default   = nil
        @alternate = nil
      end

      def execute
        project = Project::Manager.in_window(win)
        i = 0
        Runnables.file_mappings(project).each do |f|
          regex = Regexp.new(f["regex"])
          if tab.edit_view.document.mirror.path =~ regex
            if i == 0
              @default = f
            elsif i == 1
              @alternate = f
            end
            i = i + 1 #increment only for matches
          end
        end
        if @alternate
          run_tab(project.home_dir,tab, @alternate)
        elsif @default
          run_tab(project.home_dir,tab, @default)
        end
      end
    end
  end
end