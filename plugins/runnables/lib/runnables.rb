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
    TREE_TITLE = "Runnables"
    PARAMS = "__PARAMS__"
    DISPLAY_PARAMS = "__?__"
    DISPLAY_NEXT_PARAMS = "_____"

    def self.run_process(path, command, title, output = "tab")
      window = Redcar.app.focussed_window
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
      if Runnables.storage['save_project_before_running'] == true
        window.notebooks.each do |notebook|
          notebook.tabs.each do |tab|
            case tab
            when EditTab
              tab.edit_view.document.save! if tab.edit_view.document.modified?
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
        item "Runnables", :command => Runnables::ShowRunnables, :icon => File.join(Redcar::ICONS_DIRECTORY,"cog.png"), :barname => :runnables
        item "Run Tab", :command => Runnables::RunEditTabCommand, :icon => File.join(Redcar::ICONS_DIRECTORY, "control.png"), :barname => :runnables
      end
    end

    def self.storage
      @storage ||= begin
        storage = Plugin::Storage.new('runnables')
        storage.set_default('save_project_before_running', false)
        storage
      end
    end
  end
end
