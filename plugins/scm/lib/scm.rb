
require 'scm/plugin.rb'

module Redcar
  module SCM
    class Manager
      
      # should we print debugging messages? this can get pretty verbose
      def self.debug
        true
      end
      
      def self.modules
        @modules ||= begin
          mods = []
          puts "Loading Redcar SCM modules..." if debug
          
          Redcar.plugin_manager.objects_implementing(:scm_modules).each do |i|
            puts "  Found #{i.name}." if debug
            object = i.scm_modules
            if object.supported?
              if object.respond_to?(:each)
                object.each {|j| mods.push(j)}
              else
                mods.push(object)
              end
            elsif debug
              puts "    but discarding because it isn't supported on the current system."
            end
          end
          
          mods
        end
      end
      
      def self.project_loaded(window, project)
        puts "Loaded #{modules.count} SCM modules."
      end
    end
  end
end

