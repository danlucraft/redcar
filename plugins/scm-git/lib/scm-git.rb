
$:.push(
  File.expand_path(File.join(File.dirname(__FILE__), %w{.. vendor grit lib})),
  File.expand_path(File.join(File.dirname(__FILE__), %w{.. vendor mime-types lib}))
)

require 'grit'

module Redcar
  module Scm
    module Git
      class Manager
        include Redcar::Scm::Model
        
        #######
        ## SCM plugin hooks
        #####
        def self.scm_module
          Redcar::Scm::Git::Manager
        end
        
        def self.supported?
          # TODO: detect the git binary, probably do a PATH search
          true
        end
        
        #######
        ## SCM hooks
        #####
        def repository_type
          "Git"
        end
        
        def repository?(path)
          File.exist?(File.join(path, %w{.git}))
        end
      end
    end
  end
end
