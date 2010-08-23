
$:.push(
  File.expand_path(File.join(File.dirname(__FILE__), %w{.. vendor ruby-blockcache lib}))
)

require 'blockcache'
require 'scm/model'
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
          Sensitivity.new(:open_scm, Redcar.app, false, [:window_focussed]) do |window|
            project = Project::Manager.focussed_project
            not Scm::Manager.project_repositories[project].nil?
          end
        ]
      end

      def self.keymaps
        osx = Keymap.build("main", :osx) do
          link "Cmd+Shift+C", Scm::CommitMirror::SaveCommand
        end
        
        linwin = Keymap.build("main", [:linux, :windows]) do
          link "Ctrl+Shift+C", Scm::CommitMirror::SaveCommand
        end
        
        [linwin, osx]
      end
      
      def self.menus
        Menu::Builder.build do
          sub_menu "Project" do
            group(:priority => 10) do
              separator
              sub_menu "Source Control" do
                item "Create Commit", Scm::CommitMirror::OpenCommand
                item "Save Commit", Scm::CommitMirror::SaveCommand
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
        true
      end
      
      def self.modules
        @modules ||= begin
          mods = []
          puts "Loading Redcar SCM modules..." if debug
          
          Redcar.plugin_manager.objects_implementing(:scm_module).each do |i|
            puts "  Found #{i.name}." if debug
            object = i.scm_module
            
            if object.supported?
              mods.push(object)
            elsif debug
              puts "    but discarding because it isn't supported on the current system."
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
            puts "Skipping SCM module #{m.name} because it has an invalid interface." if debug
            nil
          else
            mod
          end
        }.find_all {|m| not m.nil?}
      end
      
      def self.modules_with_init
        modules_instance.find_all {|m| m.supported_commands.include? :init}
      end
      
      def self.project_loaded(project)
        # for now we only want to attempt to handle the local case
        return if project.remote?
        
        puts "#{modules.count} SCM modules loaded." if debug
        
        repo = modules_instance.find do |m|
          puts "Checking if #{project.path} is a #{m.repository_type} repository..." if debug
          m.repository?(project.path)
        end
        
        # quit if we can't find something to handle this project
        return if repo.nil?
        
        puts "  Yes it is!" if debug
        
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
            puts "Attaching a custom adapter to the project." if debug
            project.adapter = adapter
          end
          
          puts "Preparing the GUI for the current project's repository." if debug
          
          project_repositories[project]['trees'] = []
          
          if repo.supported_commands.include? :commit
            mirror = Scm::ScmChangesMirror.new(repo)
            tree = Tree.new(mirror, Scm::ScmChangesController.new(repo))
            project.window.treebook.add_tree(tree)
            tree.tree_mirror.top.each {|n| tree.expand(n)}
            project_repositories[project]['trees'].push tree
          end
          if repo.supported_commands.include? :push
            mirror = Scm::ScmCommitsMirror.new(repo)
            tree = Tree.new(mirror, Scm::ScmCommitsController.new(repo))
            project.window.treebook.add_tree(tree)
            tree.tree_mirror.top.each {|n| tree.expand(n)}
            project_repositories[project]['trees'].push tree
          end
        
          # don't steal focus from the project module.
          project.window.treebook.focus_tree(project.tree)
        rescue
          # cleanup
          project_repositories.delete project
          
          puts "*** Error loading SCM: " + $!.message
          puts $!.backtrace
        end
        
        puts "scm start took #{Time.now - start}s (included in project start time)" if debug
      end
      
      def self.project_closed(project)
        # disassociate this project with any repositories
        info = project_repositories.delete project
        return if info.nil?
        
        info['trees'].each {|t| project.window.treebook.remove_tree(t)}
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
          puts "Couldn't detect the project in the current window."
        end
        repo_info = project_repositories[project]
        
        Menu::Builder.build do
          if not project.nil?
            if repo_info.nil?
              # no repository detected
              group :priority => 40 do
                separator
                sub_menu "Create Repository From Project" do
                  Redcar::Scm::Manager.modules_with_init.sort {|a, b| a.repository_type <=> b.repository_type}.each do |m|
                    item(m.translations[:init]) do 
                      m.init!(project.path)
                      project.refresh
                        
                      Redcar::Scm::Manager.prepare(project, m)
                      
                      Application::Dialog.message_box("Created a new " + m.repository_type.capitalize + " repository in the root of your project.")
                    end
                  end
                end
              end
            else
              # TODO: display repository commands for this node here too
              # Before that, need to work out a way of caching
              # Scm#uncommited_changes as this will almost always be an
              # expensive operation.
              group :priority => 40 do
                repo = repo_info['repo']
                if repo.supported_commands.find {|i| [:switch_branch].include? i}
                  separator
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
