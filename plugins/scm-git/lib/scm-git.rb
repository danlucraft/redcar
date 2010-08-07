
$:.push(
  File.expand_path(File.join(File.dirname(__FILE__), %w{.. vendor grit lib})),
  File.expand_path(File.join(File.dirname(__FILE__), %w{.. vendor mime-types lib}))
)

require 'grit'
require 'scm-git/change'

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
          # Even with grit, we do need the binary.
          # TODO: detect the git binary, do a PATH search?
          true
        end
        
        # Whether to print debugging messages. Default to whatever scm is using.
        def self.debug
          Redcar::Scm::Manager.debug
        end
        
        #######
        ## General stuff
        #####
        
        def inspect
          %Q{#<Scm::Git::Manager "#{@repo.path}">}
        end
        
        #######
        ## SCM hooks
        #####
        attr_accessor :repo
        
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
        
        # @return [Array<Redcar::Scm::ScmMirror::Change>]
        def uncommited_changes
          # cache this for atleast this call, because it's *slow*
          status = @repo.status
          changes = []
          
          # f[0] is the path, and f[1] is the actual StatusFile
          status.changed.each {|f| changes.push(Git::Change.new(f[1]))}
          status.added.each {|f| changes.push(Git::Change.new(f[1]))}
          status.deleted.each {|f| changes.push(Git::Change.new(f[1]))}
          status.untracked.each {|f| changes.push(Git::Change.new(f[1]))}
          
          changes.sort_by {|m| m.path}
        end
      end
    end
  end
end
