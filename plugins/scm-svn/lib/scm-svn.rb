
module Redcar
  module Scm
    module Subversion
      class Manager
        include Redcar::Scm::Model
        
        def self.scm_module
          Redcar::Scm::Subversion::Manager
        end
        
        def self.supported?
          # not implemented, and hence never supported
          puts "    Subversion support is currently unimplemented" if debug
          false
        end
        
        # Whether to print debugging messages. Default to whatever scm is using.
        def self.debug
          Redcar::Scm::Manager.debug
        end
      end
    end
  end
end

