
module Redcar
  module SCM
    module Mercurial
      class Manager
        def self.scm_modules
          Redcar::SCM::Mercurial::Manager
        end
        
        def self.supported?
          # not implemented, and hence never supported
          false
        end
      end
    end
  end
end

