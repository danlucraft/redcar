require 'runnables/command_output_controller'
require 'runnables/running_process_checker'
require 'runnables/output_processor'

module Redcar
  class Runnables
    TREE_TITLE = "Runnables"

    def self.run_process(path, command, title, output = "tab")
      window = Redcar.app.focussed_window
      if command.include?("__PARAMS__")
        msg = command.gsub("__PARAMS__","__?__")
        msg = "" if msg == "__?__"
        msg_title = "Enter Command Parameters"
        out = Redcar::Application::Dialog.input(msg_title,msg)
        params = out[:value] || ""
        command = command.gsub("__PARAMS__",params)
      end
      if Runnables.storage['save_project_before_running'] == true
        window.notebooks.each do |notebook|
          notebook.tabs.each do |tab|
            case tab
            when EditTab
              tab.edit_view.document.save!
            end
          end
        end
      end
      controller = CommandOutputController.new(path, command, title)
      if output == "none"
        controller.run
      else
        if tab = previous_tab_for(command)
          tab.html_view.controller.run
          tab.focus
        else
          if output == "window"
            Redcar.app.new_window
          end
          tab = window.new_tab(HtmlTab)
          tab.html_view.controller = controller
          tab.focus
        end
      end
    end

    def self.previous_tab_for(command)
      Redcar.app.all_tabs.detect do |t|
        t.respond_to?(:html_view) &&
        t.html_view.controller.is_a?(CommandOutputController) &&
        t.html_view.controller.cmd == command
      end
    end

    def self.keymaps
      map = Keymap.build("main", [:osx, :linux, :windows]) do
        link "Ctrl+R", Runnables::RunEditTabCommand
      end
      [map, map]
    end

    def self.menus
      Menu::Builder.build do
        sub_menu "Project" do
          group(:priority => 15) {
          separator
            item "Runnables", Runnables::ShowRunnables
            item "Run Tab",   Runnables::RunEditTabCommand
          }
        end
      end
    end

    def self.runnables_context_menus(node)
      Menu::Builder.build do
        if not node.nil? and node.is_a?(Runnable)
          item("Run with parameters") do
            AppendParamsAndRunCommand.new(node).run
          end
        end
      end
    end

    def self.toolbars
      ToolBar::Builder.build do
        item "Runnables", :command => Runnables::ShowRunnables, :icon => File.join(File.dirname(__FILE__),"/../icons/cog.png"), :barname => :runnables
        item "Run Tab", :command => Runnables::RunEditTabCommand, :icon => File.join(Redcar::ICONS_DIRECTORY, "control.png"), :barname => :runnables
      end
    end

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
        custom_info["command"] = '__PARAMS__'
        custom_info["output"] = 'tab'
        custom = Runnable.new("Custom Command",@project.path,custom_info)
        [custom]
      end

      def load
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

    def self.storage
      @storage ||= begin
        storage = Plugin::Storage.new('runnables')
        storage.set_default('save_project_before_running', false)
        storage
      end
    end

    class RunnableGroup
      include Redcar::Tree::Mirror::NodeMirror

      def initialize(name,path,runnables)
        @name = name
        if runnables.any?
          @children = runnables.map do |runnable|
            Runnable.new(runnable["name"],path,runnable)
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

      def initialize(name,path,info)
        @name = name
        @info = info
        @path = path
      end

      def text
        @name
      end

      def path
        @path
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

      def right_click(tree, node)
        controller = self
        menu = Menu.new
        Redcar.plugin_manager.objects_implementing(:runnables_context_menus).each do |object|
          case object.method(:runnables_context_menus).arity
          when 1
            menu.merge(object.runnables_context_menus(node))
          when 2
            menu.merge(object.runnables_context_menus(tree, node))
          when 3
            menu.merge(object.runnables_context_menus(tree, node, controller))
          else
            puts("Invalid runnables_context_menus hook detected in "+object.class.name)
          end
        end
        Application::Dialog.popup_menu(menu, :pointer)
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

    class AppendParamsAndRunCommand < Redcar::Command
      def initialize(node)
        @node = node
      end

      def execute
        command = @node.command
        command = "#{command} __PARAMS__" unless command.include?('__PARAMS__')
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
