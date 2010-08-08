
$:.push(
  File.expand_path(File.join(File.dirname(__FILE__), %w{.. vendor ruby-git lib}))
)

require 'git'
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
          %Q{#<Scm::Git::Manager "#{@repo.dir.path}">}
        end
        
        #######
        ## SCM hooks
        #####grit
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
          
          ::Git.init(path)
        end
        
        def load(path)
          raise "Already loaded repository" if @repo
          @repo = ::Git.open(path)
        end
        
        # @return [Array<Redcar::Scm::ScmMirror::Change>]
        def uncommited_changes
          # cache this for atleast this call, because it's *slow*
          status = @repo.status
          changes = []
          
          # f[0] is the path, and f[1] is the actual StatusFile
          status.all_changes.each do |f| 
            full_path = @repo.dir.path + '/' + f[0]
            type = File.file?(full_path) ? :file : :directory
            
            if type == :directory
              subprojects[full_path] ||= begin
                project = Scm::Git::Manager.new
                project.load(full_path)
                project
              end
              
              changes.push(Git::Change.new(f[1], type, @subprojects[full_path].uncommited_changes))
            else
              changes.push(Git::Change.new(f[1], type))
            end
          end
          
          changes.sort_by {|m| m.path}
        end
        
        private
        
        def subprojects
          @subprojects ||= {}
        end
      end
    end
  end
end
