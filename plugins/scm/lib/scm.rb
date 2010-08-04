
require 'scm/model.rb'

module Redcar
  module Scm
    class Manager
      extend Redcar::HasSPI
      
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
      
      def self.modules_with_init
        modules.map {|m| m.new}.find_all {|m| m.supported_commands.include? :init}
      end
      
      def self.project_loaded(project)
        # for now we only want to attempt to handle the local case
        return if not project.adapter.is_a?(Project::Adapters::Local)
        
        puts "#{modules.count} SCM modules loaded." if debug
        
        repo = modules.map {|m| m.new}.find do |m|
          begin
            assert_interface(m, Redcar::Scm::Model)
          rescue RuntimeError => e
            puts "Skipping SCM module #{m.name} because it has an invalid interface." if debug
            false
          else
            puts "Checking if #{project.path} is a #{m.repository_type} repository..." if debug
            m.repository?(project.path)
          end
        end
        
        # quit if we can't find something to handle this project
        return if repo.nil?
        
        puts "  Yes it is!" if debug
        
        # load the repository and inject adapter if there is one
        repo.load(project.path)
        adapter = repo.adapter(project.adapter)
        if not adapter.nil?
          puts "Attaching a custom adapter to the project." if debug
          project.adapter = adapter
        end
        
        prepare(project, repo)
      end
      
      def self.prepare(project, repo)
        # associate this repository with a project internally
        project_repositories[project] = repo
        puts "Preparing the GUI for the current project."
      end
      
      def self.project_closed(project)
        # disassociate this project with any repositories
        project_repositories.delete project
      end
      
      def self.project_context_menus(tree, node, controller)
        # Search for the current project
        project = Redcar::Project.window_projects.values.find{|p| p.tree == tree}
        repo = project_repositories[project]
        
        Menu::Builder.build do
          if repo.nil?
            # no repository detected
            group :priority => 40 do
              separator
              sub_menu "Create Repository From Project" do
                Redcar::Scm::Manager.modules_with_init.sort {|a, b| a.repository_type <=> b.repository_type}.each do |m|
                  item(m.command_names[:init].capitalize) do 
                    m.init!(project.path)
                    m.load(project.path)
                    project.refresh
                    
                    Redcar::Scm::Manager.prepare(project, m)
                  end
                end
              end
            end
          else
            # display repository commands for this node
            
          end
        end
      end
    end
  end
end
