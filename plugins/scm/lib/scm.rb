
gem "ruby-blockcache"
require 'blockcache'

require 'scm/model'
require 'scm/commands'
require 'scm/commit_mirror'
require 'scm/diff_mirror'
require 'scm/scm_changes_controller'
require 'scm/scm_changes_mirror'
require 'scm/scm_changes_mirror/drag_controller'
require 'scm/scm_changes_mirror/changes_node'
require 'scm/scm_changes_mirror/change'
require 'scm/scm_commits_controller'
require 'scm/scm_commits_mirror'
require 'scm/scm_commits_mirror/commits_node'
require 'scm/scm_commits_mirror/commit'

module Redcar
  module Scm
    ICONS_DIR = File.expand_path(File.join(File.dirname(__FILE__), %w{.. icons}))

    class Manager
      extend Redcar::HasSPI

      def self.sensitivities
        [
          Sensitivity.new(:open_commit_tab, Redcar.app, false, [:tab_focussed]) do |tab|
            tab and
            tab.is_a?(EditTab) and
            tab.edit_view.document.mirror.is_a?(Scm::CommitMirror)
          end,
          Sensitivity.new(:open_scm, Redcar.app, false,
            [:window_focussed,:tree_removed,:tree_added]) do |window|
            project = Project::Manager.focussed_project
            Scm::Manager.project_repositories[project]
          end
        ]
      end

      def self.keymaps
        osx = Keymap.build("main", :osx) do
          link "Cmd+Shift+C", Scm::CommitMirror::CommitChangesCommand
          link "Cmd+Shift+.", :command => Scm::CommitMirror::CommitChangesCommand, :value => [:commit, [Scm::ScmChangesMirror, Scm::ScmChangesController]]
        end

        linwin = Keymap.build("main", [:linux, :windows]) do
          link "Ctrl+Shift+C", Scm::CommitMirror::CommitChangesCommand
        end

        [linwin, osx]
      end

      def self.menus
        Menu::Builder.build do
          sub_menu "Project" do
            group(:priority => 10) do
              separator
              sub_menu "Source Control" do
                Scm::Manager.modules_with_remote_init.sort {|a, b| a.repository_type <=> b.repository_type}.each do |m|
                  item m.translations[:remote_init], :command => Scm::RemoteInitCommand, :value => m
                end
                separator
                item "Toggle Changes Tree", :command => Scm::ToggleScmTreeCommand, :value => [:commit, [Scm::ScmChangesMirror, Scm::ScmChangesController]]
                item "Toggle Commits Tree", :command => Scm::ToggleScmTreeCommand, :value => [:push, [Scm::ScmCommitsMirror, Scm::ScmCommitsController]]
                separator
                item "Create Commit", :command => Scm::CommitMirror::CreateCommitCommand
                item "Save Commit", :command => Scm::CommitMirror::CommitChangesCommand
              end
            end
          end
        end
      end

      def self.project_repositories
        @project_repositories ||= {}
      end

      # should we print debugging messages? this can get pretty verbose
      def self.debug
        ARGV.include?('--debug')
      end

      def self.modules
        @modules ||= begin
          mods = []
          Redcar.log.debug "SCM Loading Redcar SCM modules..."

          Redcar.plugin_manager.objects_implementing(:scm_module).each do |i|
            Redcar.log.debug "SCM   Found #{i.name}."
            object = i.scm_module

            if object.supported?
              mods.push(object)
            elsif debug
              Redcar.log.debug  "SCM     but discarding because it isn't supported on the current system."
            end
          end

          mods
        end
      end

      # Returns a list of instances of SCM modules. This list has already been
      # filtered for invalid modules.
      def self.modules_instance
        modules.map {|m|
          mod = m.new
          begin
            assert_interface(mod, Redcar::Scm::Model)
          rescue RuntimeError => e
            Redcar.log.debug "SCM Skipping SCM module #{m.name} because it has an invalid interface."
            nil
          else
            mod
          end
        }.find_all {|m| not m.nil?}
      end

      def self.modules_with_init
        modules_instance.find_all {|m| m.supported_commands.include? :init}
      end

      def self.modules_with_remote_init
        modules_instance.find_all {|m| m.supported_commands.include? :remote_init}
      end

      def self.project_loaded(project)
        # for now we only want to attempt to handle the local case
        return if project.remote?

        Redcar.log.debug "SCM #{modules.count} SCM modules loaded."

        repo = modules_instance.find do |m|
          Redcar.log.debug "SCM Checking if #{project.path} is a #{m.repository_type} repository..."
          m.repository?(project.path)
        end

        # quit if we can't find something to handle this project
        return if repo.nil?

        Redcar.log.debug "SCM   Yes it is!"

        prepare(project, repo)
      end

      def self.prepare(project, repo)
        start = Time.now
        begin
          # associate this repository with a project internally
          project_repositories[project] = {'repo' => repo}

          # load the repository and inject adapter if there is one
          repo.load(project.path)
          adapter = repo.adapter(project.adapter)
          if not adapter.nil?
            Redcar.log.debug "SCM Attaching a custom adapter to the project."
            project.adapter = adapter
          end

          project_repositories[project]['trees'] = []
        rescue
          # cleanup
          info = project_repositories.delete project

          Redcar.log.error "*** Error loading SCM: " + $!.message
          puts $!.backtrace
        end

        Redcar.log.debug "SCM start took #{Time.now - start}s"
      end

      def self.project_closed(project,window)
        # disassociate this project with any repositories
        info = project_repositories.delete project
        return if info.nil?

        info['trees'].each {|t| window.treebook.remove_tree(t)}
      end

      def self.refresh_trees
        project_repositories.each do |project, info|
          project.refresh
          info['trees'].each {|t| t.refresh}
        end
      end

      def self.project_context_menus(tree, node, controller)
        # Search for the current project
        project = Project::Manager.in_window(Redcar.app.focussed_window)
        if project.nil?
          Redcar.log.debug "SCM Couldn't detect the project in the current window."
        end
        repo_info = project_repositories[project]
        init_modules = Redcar::Scm::Manager.modules_with_init

        Menu::Builder.build do
          if not project.nil?
            if repo_info.nil? and init_modules.length > 0
              # no repository detected
              group :priority => 40 do
                separator
                sub_menu "Create Repository From Project" do
                  init_modules.sort {|a, b| a.repository_type <=> b.repository_type}.each do |m|
                    item(m.translations[:init]) do
                      m.init!(project.path)
                      project.refresh

                      Redcar::Scm::Manager.prepare(project, m)

                      Application::Dialog.message_box("Created a new " + m.repository_type.capitalize + " repository in the root of your project.")
                    end
                  end
                end
              end
            elsif repo_info
              group :priority => 40 do
                repo = repo_info['repo']
                if repo.supported_commands.find {|i| [:switch_branch, :pull, :pull_targetted].include? i}
                  separator
                end
                if repo.supported_commands.include?(:pull)
                  item (repo.translations[:pull]) do
                    repo.pull!

                    # refresh tree views
                    project.refresh
                    repo_info['trees'].each {|t| t.refresh}
                  end
                end
                if repo.supported_commands.include?(:pull_targetted)
                  lazy_sub_menu repo.translations[:pull_targetted] do
                    repo.pull_targets.sort.each do |target|
                      action = lambda do
                        begin
                          repo.pull!(target)

                          # refresh tree views
                          project.refresh
                          repo_info['trees'].each {|t| t.refresh}
                        rescue
                          Redcar::Application::Dialog.message_box($!.message)
                          puts $!.backtrace
                        end
                      end

                      item target, &action
                    end
                  end
                end
                if repo.supported_commands.include?(:switch_branch)
                  lazy_sub_menu repo.translations[:switch_branch] do
                    current = repo.current_branch
                    repo.branches.sort.each do |branch|
                      action = lambda {
                        begin
                          repo.switch!(branch)

                          # refresh tree views
                          project.refresh
                          repo_info['trees'].each {|t| t.refresh}
                        rescue
                          Redcar::Application::Dialog.message_box($!.message)
                          puts $!.backtrace
                        end
                      }

                      item branch, :type => :radio, :active => (branch == current), &action
                    end
                  end
                end
              end
            end
          end
        end
      end

      def self.open_commit_tab(repo, change=nil)
        tab = Redcar.app.focussed_window.new_tab(Redcar::EditTab)
        edit_view = tab.edit_view
        mirror = Scm::CommitMirror.new(repo, change)
        edit_view.document.mirror = mirror
        edit_view.grammar = "Diff"
        tab.focus

        mirror.add_listener(:change) do
          tab.close

          project = Project::Manager.focussed_project
          repo_info = project_repositories[project]
          repo_info['trees'].each {|t| t.refresh}
        end
      end
    end
  end
end
