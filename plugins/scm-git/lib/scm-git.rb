
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
        #####
        attr_accessor :repo
        
        def repository_type
          "git"
        end
        
        def repository?(path)
          File.exist?(File.join(path, %w{.git}))
        end
        
        def supported_commands
          [:init, :commit, :index]
        end
        
        def init!(path)
          # Be nice and don't blow away another repository accidentally.
          return nil if File.exist?(File.join(path, %w{.git}))
          
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
            full_path = File.join(@repo.dir.path, f[0])
            type = File.file?(full_path) ? :file : :directory
            
            if type == :directory
              subprojects[full_path] ||= begin
                project = Scm::Git::Manager.new
                project.load(full_path)
                project
              end
              
              changes.push(Scm::Git::Change.new(f[1], self, type, @subprojects[full_path].uncommited_changes))
            else
              changes.push(Scm::Git::Change.new(f[1], self, type))
            end
          end
          
          changes.sort_by {|m| m.path}
        end
        
        # REQUIRED for :index. Adds a new file to the index.
        def index_add(change)
          # delegate to the proper submodule
          if self != change.repo
            change.repo.index_add(change)
            return
          end
          
          @repo.add(change.path)
        end
        
        # REQUIRED for :index. Ignores a new file so it won't show in changes.
        def index_ignore(change)
          # delegate to the proper submodule
          if self != change.repo
            change.repo.index_ignore(change)
            return
          end
          
          gitignore = File.new(File.join(repo.dir.path, '.gitignore'), 'a')
          gitignore.syswrite(change.path + "\n")
          gitignore.close
        end
        
        # REQUIRED for :index. Reverts a file to its last commited state.
        def index_revert(change)
          # delegate to the proper submodule
          if self != change.repo
            change.repo.index_revert(change)
            return
          end
          
          if change.git_status[0,1] != ' '
            # Git requires us to unindex any changes before we can revert them.
            index_unsave(change)
          end
          if change.git_status[0,1] == 'A'
            # if this was a new file, then revert it by deleting it
            File.unlink(File.join(@repo.dir.path, change.path))
          else
            # otherwise checkout the old version
            @repo.checkout_file('HEAD', change.path)
          end
        end
        
        # REQUIRED for :index. Reverts a file in the index back to it's 
        # last commited state, but leaves the file intact.
        def index_unsave(change)
          # delegate to the proper submodule
          if self != change.repo
            change.repo.index_unsave(change)
            return
          end
          
          @repo.reset('HEAD', :file => change.path)
        end
        
        # REQUIRED for :index. Saves changes made to a file in the index.
        def index_save(change)
          # delegate to the proper submodule
          if self != change.repo
            change.repo.index_save(change)
            return
          end
          
          @repo.add(change.path)
        end
        
        # REQUIRED for :index. Restores a file to the last known state of
        # the file. This may be from the index, or the last commit.
        def index_restore(change)
          # delegate to the proper submodule
          if self != change.repo
            change.repo.index_restore(change)
            return
          end
          
          @repo.checkout_file('HEAD', change.path)
        end
        
        # REQUIRED for :index. Marks a file as deleted in the index.
        def index_delete(change)
          # delegate to the proper submodule
          if self != change.repo
            change.repo.index_delete(change)
            return
          end
          
          @repo.remove(change.path)
        end
        
        # REQUIRED for :commitable changes. Commits the currently staged 
        # changes in the subproject.
        def commit!(change, message)
          # delegate to the proper submodule
          if self != change.repo
            change.repo.commit!(change)
            return
          end
          
          # redelegate the commit to the subproject to handle
          full_path = File.join(@repo.dir.path, change.path)
          subprojects[full_path].commit!(message)
        end
      
        # REQUIRED for :commitable changes. Gets a commit message for the change
        # to be commited.
        def commit_message(change)
          # delegate to the proper submodule
          if self != change.repo
            change.repo.commit!(change)
            return
          end
          
          # redelegate the call to the subproject to handle
          full_path = File.join(@repo.dir.path, change.path)
          subprojects[full_path].commit_message
        end
        
        def commit_message
          "\n\n" + @repo.lib.command("status")
        end
        
        private
        
        def subprojects
          @subprojects ||= {}
        end
      end
    end
  end
end
