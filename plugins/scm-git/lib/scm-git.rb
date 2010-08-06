
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
          "git"
        end
        
        def repository?(path)
          File.exist?(File.join(path, %w{.git}))
        end
        
        def supported_commands
          [:init, :commit]
        end
        
        def init!(path)
          # Be nice and don't blow away another repository accidentally.
          return nil if File.exist?(path + '/.git')
          # Grit doesn't support this in the normal API, so make the call directly.
          # One day I'll fill in the todo code on Grit::Repo.init(path)
          Grit::GitRuby::Repository.init(path + '/.git', false)
          true
        end
        
        def load(path)
          @repo = Grit::Repo.new(path)
        end
      end
    end
  end
end
