
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
      end
    end
  end
end

