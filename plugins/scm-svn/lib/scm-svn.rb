
module Redcar
  module SCM
    module Subversion
      class Manager
        def self.scm_modules
          Redcar::SCM::Subversion::Manager
        end
        
        def self.supported?
          # not implemented, and hence never supported
          false
        end
      end
    end
  end
end

