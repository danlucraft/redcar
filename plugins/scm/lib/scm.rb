
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
            
            begin
              assert_interface(object, Redcar::Scm::Model)
              if object.supported?
                mods.push(object)
              elsif debug
                puts "    but discarding because it isn't supported on the current system."
              end
            rescue RuntimeError => e
              puts "    but discarding because it doesn't implement the required interface."
            end
          end
          
          mods
        end
      end
      
      def self.project_loaded(window, project)
        puts "Loaded #{modules.count} SCM modules." if debug
        
        for m in modules
          print "Checking if #{project.path} is a #{m.repo_type} repository... " if debug
          
          if m.repo?(project.path)
            puts "Yes!"
          else
            puts "No, lets try again..."
          end
        end
      end
    end
  end
end

