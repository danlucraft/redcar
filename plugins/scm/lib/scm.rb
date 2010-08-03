
require 'scm/model.rb'

module Redcar
  module Scm
    class Manager
      extend Redcar::HasSPI
      
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
      
      def self.project_loaded(window, project)
        # for now we only want to attempt to handle the local case
        return if not project.adapter.is_a?(Project::Adapters::Local)
        
        puts "Loaded #{modules.count} SCM modules." if debug
        
        repo = modules.map {|m| m.new}.find do |m|
          begin
            assert_interface(m, Redcar::Scm::Model)
          rescue RuntimeError => e
            puts "Skipping repo module #{m.name} because it has an invalid interface." if debug
            false
          else
            puts "Checking if #{project.path} is a #{m.repo_type} repository..." if debug
            m.repo?(project.path)
          end
        end
        
        if not repo.nil?
          puts "  Yes it is!" if debug
          # do stuff, like load the repo
        end
      end
    end
  end
end

