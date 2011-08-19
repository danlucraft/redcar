require 'runnables/command_output_controller'
require 'runnables/commands'
require 'runnables/output_processor'
require 'runnables/running_process_checker'
require 'runnables/tree_mirror/nodes/runnable'
require 'runnables/tree_mirror/nodes/runnable_group'
require 'runnables/tree_mirror/nodes/runnable_type_group'
require 'runnables/tree_mirror/tree_controller'
require 'runnables/tree_mirror/tree_mirror'

module Redcar
  class Runnables
    TREE_TITLE          = "Runnables"
    PARAMS              = "__PARAMS__"
    DISPLAY_PARAMS      = "__?__"
    DISPLAY_NEXT_PARAMS = "_____"
    LINE_HOLDER         = "__LINE__"
    PATH_HOLDER         = "__PATH__"
    NAME_HOLDER         = "__NAME__"

    def self.run_process(path, command, title, output = "tab")
      window = Redcar.app.focussed_window
      command = Runnables.substitute_variables(window,command)
      return unless command
      if Runnables.storage['save_project_before_running'] == true
        window.notebooks.each do |notebook|
          notebook.tabs.each do |tab|
            tab.edit_view.document.save! if tab.is_a?(EditTab) and tab.edit_view.document.modified?
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
          tab.icon = :cog
          tab.focus
        end
      end
    end

    # Replaces placeholders in commands with values, like __PATH__,
    # __LINE__, __NAME__ and __PARAMS__
    def self.substitute_variables(window,command)
      tab = window.focussed_notebook_tab
      if tab and tab.is_a?(EditTab)
        if command.include?(PATH_HOLDER)
          path = tab.edit_view.document.path
          command.gsub!(PATH_HOLDER, path)
          if command.include?(LINE_HOLDER)
            line = tab.edit_view.document.cursor_line + 1
            command.gsub!(LINE_HOLDER, line.to_s)
          end
        end
        if command.include?(NAME_HOLDER)
          name = File.basename(tab.edit_view.document.path)
          idx  = name.rindex(".") if name.include?(".")
          name = name[0,idx] if idx
          command.gsub!(NAME_HOLDER, name.to_s)
        end
      end
      while command.include?(PARAMS)
        msg = command.sub(PARAMS,DISPLAY_PARAMS)
        msg = msg.gsub(PARAMS,DISPLAY_NEXT_PARAMS)
        msg = "" if msg == DISPLAY_PARAMS
        msg_title = "Enter Command Parameters"
        out = Redcar::Application::Dialog.input(msg_title,msg)
        params = out[:value] || ""
        return if out[:button] == :cancel
        command = command.sub(PARAMS,params)
      end
      command
    end

    def self.file_mappings(project)
      file_runners = []
      if project
        runnable_file_paths = project.config_files("runnables/*.json")
        runnable_file_paths.each do |path|
          json = File.read(path)
          this_file_runners = JSON(json)["file_runners"]
          file_runners += this_file_runners || []
        end
      end
      file_runners
    end

    def self.previous_tab_for(command)
      Redcar.app.all_tabs.detect do |t|
        t.respond_to?(:html_view) &&
        t.html_view.controller.is_a?(CommandOutputController) &&
        t.html_view.controller.cmd == command
      end
    end

    def self.keymaps
      linwin = Keymap.build("main", [:linux, :windows]) do
        link "Ctrl+Alt+Shift+R", Runnables::ShowRunnables
        link "Ctrl+R", Runnables::RunEditTabCommand
        link "Ctrl+Alt+R", Runnables::RunAlternateEditTabCommand
      end

      osx = Keymap.build("main", :osx) do
        link "Cmd+Alt+Shift+R", Runnables::ShowRunnables
        link "Cmd+R", Runnables::RunEditTabCommand
        link "Cmd+Alt+R", Runnables::RunAlternateEditTabCommand
      end
      [linwin,osx]
    end

    def self.menus
      Menu::Builder.build do
        sub_menu "Project" do
          group(:priority => 15) {
            separator
            item "Runnables", Runnables::ShowRunnables
            item "Run Tab",   Runnables::RunEditTabCommand
            item "Alternate Run Tab", Runnables::RunAlternateEditTabCommand
            separator
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
        item "Runnables", :command => Runnables::ShowRunnables, :icon => File.join(Redcar.icons_directory,"cog.png"), :barname => :project
        item "Run Tab", :command => Runnables::RunEditTabCommand, :icon => File.join(Redcar.icons_directory, "control.png"), :barname => :project
      end
    end

    def self.storage
      @storage ||= begin
        storage = Plugin::Storage.new('runnables')
        storage.set_default('save_project_before_running', false)
        storage
      end
    end

    def self.quit_guard
      Runnables::RunningProcessChecker.new(
        Redcar.app.all_tabs.select {|t| t.is_a?(HtmlTab)},
        "Kill all and quit?"
      ).check
    end

    def self.close_window_guard(win)
      Runnables::RunningProcessChecker.new(
        win.notebooks.map(&:tabs).flatten.select {|t| t.is_a?(HtmlTab)},
        "Kill them and close the window?"
      ).check
    end

    def self.project_closed(project,window)
        rtree = window.treebook.trees.detect { |t|
          t.tree_mirror.is_a? Runnables::TreeMirror
        }
        rtree.close if rtree
      end
  end
end