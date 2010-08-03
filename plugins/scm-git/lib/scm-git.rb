
$:.push(
  File.expand_path(File.join(File.dirname(__FILE__), %w{.. vendor grit lib})),
  File.expand_path(File.join(File.dirname(__FILE__), %w{.. vendor mime-types lib}))
)

require 'grit'

module Redcar
  module SCM
    module Git
      class Manager
        def self.scm_modules
          Redcar::SCM::Git::Manager
        end
        
        def self.supported?
          # TODO: detect the git binary
          true
        end
      end
    end
  end
end
