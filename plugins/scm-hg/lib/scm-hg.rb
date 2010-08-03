
module Redcar
  module Scm
    module Mercurial
      class Manager
        def self.scm_module
          Redcar::Scm::Mercurial::Manager
        end
        
        def self.supported?
          # not implemented, and hence never supported
          false
        end
      end
    end
  end
end

