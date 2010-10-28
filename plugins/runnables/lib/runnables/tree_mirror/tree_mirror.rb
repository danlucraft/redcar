module Redcar
  class Runnables
    class TreeMirror
      include Redcar::Tree::Mirror

      attr_accessor :last_loaded

      def initialize(project)
        @project = project
      end

      def runnable_file_paths
        @project.config_files("runnables/*.json")
      end

      def last_updated
        runnable_file_paths.map{ |p| File.mtime(p) }.max
      end

      def changed?
        !last_loaded || last_loaded < last_updated
      end

      def custom_command
        custom_info = {}
        custom_info["command"] = PARAMS
        custom_info["output"] = 'tab'
        custom = Runnable.new("Custom Command",@project.path,custom_info)
        [custom]
      end

      def load
        begin
          groups = {}
          runnable_file_paths.each do |path|
            runnables = []
            name = File.basename(path,".json")
            json = File.read(path)
            this_runnables = JSON(json)["commands"]
            runnables += this_runnables || []
            groups[name.to_s] = runnables.to_a
          end
        rescue Object => e
          Redcar::Application::Dialog.message_box("There was an error parsing Runnables: #{e.message}")
          groups = {}
        end

        if groups.any?
          groups.map do |name, runnables|
            RunnableGroup.new(name,@project.path,runnables)
          end
        else
          [HelpItem.new]
        end
      end

      def title
        TREE_TITLE
      end

      def top
        custom_command + load
      end
    end
  end
end