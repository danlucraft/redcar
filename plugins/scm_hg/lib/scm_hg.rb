
module Redcar
  module Scm
    module Mercurial
      class Manager
        include Redcar::Scm::Model
        
        def self.scm_module
          Redcar::Scm::Mercurial::Manager
        end
        
        def self.supported?
          # not implemented, and hence never supported
          Redcar.log.debug "SCM     Mercurial support is currently unimplemented"
          false
        end
      
        # Whether to print debugging messages. Default to whatever scm is using.
        def self.debug
          Redcar::Scm::Manager.debug
        end
        
        def debug
          Redcar::Scm::Mercurial::Manager.debug
        end
      end
    end
  end
end

