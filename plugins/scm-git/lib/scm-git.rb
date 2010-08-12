
$:.push(
  File.expand_path(File.join(File.dirname(__FILE__), %w{.. vendor ruby-git lib}))
)

require 'git'
require 'scm-git/change'
require 'scm-git/commit'

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
        
        def debug
          Redcar::Scm::Git::Manager.debug
        end
        
        #######
        ## General stuff
        #####
        
        def inspect
          %Q{#<Scm::Git::Manager "#{@repo.dir.path}">}
        end
        
        def cache
          @cache ||= begin
            c = Redcar::Scm::Cache.new
            c.add('branches', 15) { @repo.lib.branches_all }
            c.add('status', 5) { @repo.status }
            c.add('full status', 5) { @repo.lib.full_status }
            c.add('config', 30) { @repo.lib.config_list }
            c.add('log', 500) do |start, finish| 
              @repo.lib.log_commits(:between => [start, finish]).reverse.map do |c|
                @repo.gcommit(c)
              end
            end
            c
          end
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
          [:init, :commit, :index, :switch_branch, :push]
        end
        
        def refresh
          cache.refresh
          subprojects.values.each {|p| p.refresh}
        end
        
        def init!(path)
          # Be nice and don't blow away another repository accidentally.
          return nil if File.exist?(File.join(path, %w{.git}))
          
          ::Git.init(path)
        end
        
        def load(path)
          raise "Already loaded repository" if @repo
          @repo = ::Git.open(path)
          cache.refresh
        end
        
        # @return [Array<Redcar::Scm::ScmMirror::Change>]
        def uncommited_changes          
          changes = []
          
          # f[0] is the path, and f[1] is the actual StatusFile
          cache['status'].all_changes.each do |f| 
            full_path = File.join(@repo.dir.path, f[0])
            type = (((not File.exist?(full_path)) or File.file?(full_path)) ? :file : :directory)
            
            if type == :directory and File.exist?(File.join(full_path, '.git'))
              type = :sub_project
            end
            
            if type == :sub_project
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
          cache.refresh
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
          cache.refresh
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
          cache.refresh
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
          cache.refresh
        end
        
        # REQUIRED for :index. Saves changes made to a file in the index.
        def index_save(change)
          # delegate to the proper submodule
          if self != change.repo
            change.repo.index_save(change)
            return
          end
          
          @repo.add(change.path)
          cache.refresh
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
          cache.refresh
        end
        
        # REQUIRED for :index. Marks a file as deleted in the index.
        def index_delete(change)
          # delegate to the proper submodule
          if self != change.repo
            change.repo.index_delete(change)
            return
          end
          
          @repo.remove(change.path)
          cache.refresh
        end
        
        # REQUIRED for :commit. Commits the currently indexed changes 
        # in the subproject.
        #
        # @param change Required for :commitable changes. Ignore if
        # you don't provide these.
        def commit!(message, change=nil)
          if change
            # delegate to the proper submodule
            if self != change.repo
              change.repo.commit!(change)
              return
            end
            
            # redelegate the commit to the subproject to handle
            full_path = File.join(@repo.dir.path, change.path)
            subprojects[full_path].commit!(message)
          else
            @repo.commit(message)
            cache.refresh
          end
        end
        
        # REQUIRED for :commit. Gets a default commit message for the 
        # currently indexed changes.
        #
        # @param change Required for :commitable changes. Ignore if
        # you don't provide these.
        def commit_message(change=nil)
          if change
            # delegate to the proper submodule
            if self != change.repo
              change.repo.commit!(change)
              return
            end
          
            # redelegate the call to the subproject to handle
            full_path = File.join(@repo.dir.path, change.path)
            subprojects[full_path].commit_message
          else
            "\n\n" + cache['full status']
          end
        end
        
        # REQUIRED for :switch_branch. Returns an array of branch names.
        #
        # @return [Array<String>]
        def branches
          cache['branches'].map {|b| b[0]}.select {|b| not b.include? "/" }
        end
        
        # REQUIRED for :switch_branch. Returns the name of the current branch.
        def current_branch
          cache['branches'].select { |b| b[1] }.first[0]
        end
        
        # REQUIRED for :switch_branch. Switches to the named branch.
        def switch!(branch)
          @repo.checkout(branch)
          cache.refresh
        end
        
        # REQUIRED for :push. Returns an array of unpushed changesets.
        #
        # @return [Array<Redcar::Scm::ScmMirror::Commit>]
        def unpushed_commits
          # Hit `git config -l` to figure out which remote/ref this branch uses for pushing.
          remote = cache['config']['branch.' + current_branch + '.remote']
          merge = cache['config']['branch.' + current_branch + '.merge']
          
          # Hit .git/remotes/$REMOTE/$REF to find out which revision that ref is at.
          merge.gsub!(/^refs\/heads\//, '')
          ref_file = File.join(@repo.dir.path, '.git', 'refs', 'remotes', remote, merge)
          ref_file = File.new(ref_file, 'r');
          r_ref = ref_file.sysread(40)
          ref_file.close()
          
          # Hit .git/refs/heads/$BRANCH to figure out which revision we're at locally.
          ref_file = File.join(@repo.dir.path, '.git', 'refs', 'heads', current_branch)
          ref_file = File.new(ref_file, 'r');
          l_ref = ref_file.sysread(40)
          ref_file.close()
          
          # Hit `git log $R_REV..$L_REV` to get a list of commits that are unpushed.          
          cache['log', r_ref, l_ref].map {|c| Scm::Git::Commit.new(c)}
        end
        
        # REQUIRED for :push. Pushes all current changesets to the remote
        # repository.
        def push!
          raise "Scm.push! not implemented." if supported_commands.include?(:push)
          nil
        end
        
        private
        
        def subprojects
          @subprojects ||= {}
        end
      end
    end
  end
end
