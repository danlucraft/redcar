
$:.push(
  File.expand_path(File.join(File.dirname(__FILE__), %w{.. vendor ruby-git lib}))
)

require 'git'
require 'scm_git/config_file'
require 'scm_git/change'
require 'scm_git/commit'

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
          if @repo
            %Q{#<Scm::Git::Manager "#{@repo.dir.path}">}
          else
            %Q{#<Scm::Git::Manager>}
          end
        end
        
        def cache
          @cache ||= begin
            c = ::BlockCache.new
            c.add('branches', 15) do
              #@repo.lib.branches_all
              
              head = File.read(File.join(@repo.dir.path, '.git', 'HEAD')).strip
              branches = Dir.glob(File.join(@repo.dir.path, '.git', 'refs', 'heads', '*')).map {|f| File.basename(f)}
              
              branches.map {|b| [b, ('ref: refs/heads/' + b == head)]}
            end
            c.add('all branches', 15) do
              raise "not implemented"
            end
            c.add('status', 5) { @repo.status }
            c.add('full status', 5) { @repo.lib.full_status }
            c.add('config', 30) do
              config = Scm::Git::ConfigFile.parse(File.join(@repo.dir.path, '.git', 'config'))
              conf = {}
              
              config.each do |key, values|                
                prefix = key.sub(/^([a-z]+) "(.+)"$/i, '\1.\2')
                
                values.each do |key2, value|
                  conf[prefix + '.' + key2] = value
                end
              end
              
              conf
            end
            c.add('log', 60*60) do |start, finish| 
              @repo.lib.log_commits(:between => [start, finish]).reverse.map do |c|
                @repo.gcommit(c)
              end
            end
            c.add('submodules', 60*60) do
              begin
                modules = Scm::Git::ConfigFile.parse(File.join(@repo.dir.path, '.gitmodules'))
                
                mods = {}
                modules.each {|k, v|
                  mod = Scm::Git::Manager.new
                  mod.load(File.join(@repo.dir.path, v['path']))
                  mods[v['path']] = mod
                }
                mods
              rescue Errno::ENOENT => e
                {}
              end
            end
            c
          end
        end
        
        #######
        ## SCM hooks
        #####
        attr_reader :repo
        
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
        
        # @return [Array<Redcar::Scm::ScmChangeMirror::Change>]
        def indexed_changes
          prepare_changes(true)
        end
        
        # @return [Array<Redcar::Scm::ScmChangeMirror::Change>]
        def unindexed_changes
          prepare_changes(false)
        end
        
        private 
        
        def prepare_changes(indexed)
          # f[0] is the path, and f[1] is the actual StatusFile
          cache['status'].all_changes.find_all {|c| valid_change?(c[1].type_raw, indexed)}.map do |f| 
            full_path = File.join(@repo.dir.path, f[0])
            type = (((not File.exist?(full_path)) or File.file?(full_path)) ? :file : :directory)
            
            if type == :directory and File.exist?(File.join(full_path, '.git'))
              type = :sub_project
            end
            
            if type == :sub_project
              Scm::Git::Change.new(f[1], self, type, indexed, cache['submodules'][f[0]].uncommited_changes)
            else
              Scm::Git::Change.new(f[1], self, type, indexed)
            end
          end.sort_by {|m| m.path}
        end
        
        def valid_change?(type, indexed)
          if (not indexed) and type[1,1] != " "
            true
          elsif indexed
            not ([" ", "?", "U"].include? type[0,1])
          else
            false
          end
        end
        
        public
        
        # REQUIRED for :index. Adds a new file to the index.
        def index_add(change)
          # delegate to the proper submodule
          if self != change.repo
            return change.repo.index_add(change)
          end
          
          @repo.add(change.path)
          cache.refresh
          true # refresh trees
        end
        
        # REQUIRED for :index. Ignores a new file so it won't show in changes.
        def index_ignore(change)
          # delegate to the proper submodule
          if self != change.repo
            change.repo.index_ignore(change)
            return
          end
          
          gitignore = File.new(File.join(repo.dir.path, '.gitignore'), 'r+')
          
          # Check the last byte of the file for a newline
          gitignore.seek(-1, IO::SEEK_END)
          if gitignore.sysread(1) != "\n"
            gitignore.syswrite("\n")
          end
          
          gitignore.syswrite(change.path + "\n")
          gitignore.close
          cache.refresh
          true # refresh trees
        end
        
        # REQUIRED for :index. Reverts a file to its last commited state.
        def index_revert(change)
          # delegate to the proper submodule
          if self != change.repo
            return change.repo.index_revert(change)
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
          true # refresh trees
        end
        
        # REQUIRED for :index. Reverts a file in the index back to it's 
        # last commited state, but leaves the file intact.
        def index_unsave(change)
          # delegate to the proper submodule
          if self != change.repo
            return change.repo.index_unsave(change)
          end
          
          if change.git_status == 'R '
            paths = change.path.split(' -> ')
            paths.each do |p|
              @repo.reset('HEAD', :file => p)
            end
            
            Dir.chdir(@repo.dir.path) do
              FileUtils.mv(paths[1], paths[0])
            end
          else
            @repo.reset('HEAD', :file => change.path)
          end
          
          cache.refresh
          true # refresh trees
        end
        
        # REQUIRED for :index. Saves changes made to a file in the index.
        def index_save(change)
          # delegate to the proper submodule
          if self != change.repo
            return change.repo.index_save(change)
          end
          
          @repo.add(change.path)
          cache.refresh
          true # refresh trees
        end
        
        # REQUIRED for :index. Restores a file to the last known state of
        # the file. This may be from the index, or the last commit.
        def index_restore(change)
          # delegate to the proper submodule
          if self != change.repo
            return change.repo.index_restore(change)
          end
          
          @repo.checkout_file('HEAD', change.path)
          cache.refresh
          true # refresh trees
        end
        
        # REQUIRED for :index. Marks a file as deleted in the index.
        def index_delete(change)
          # delegate to the proper submodule
          if self != change.repo
            return change.repo.index_delete(change)
          end
          
          @repo.remove(change.path)
          cache.refresh
          true # refresh trees
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
              return change.repo.commit!(change)
            end
            
            # redelegate the commit to the subproject to handle
            cache['submodules'][change.path].commit!(message)
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
              return change.repo.commit!(change)
            end
          
            # redelegate the call to the subproject to handle
            cache['submodules'][change.path].commit_message
          else
            "\n\n" + cache['full status']
          end
        end
        
        # REQUIRED for :switch_branch. Returns an array of branch names.
        #
        # @return [Array<String>]
        def branches
          cache['branches'].map {|b| b[0]}
        end
        
        # REQUIRED for :switch_branch. Returns the name of the current branch.
        def current_branch
          b = cache['branches'].select { |b| b[1] }.first
          
          b.nil? ? "" : b[0]
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
          push_target = cache['config']['branch.' + current_branch + '.push'] || cache['config']['branch.' + current_branch + '.merge']
          
          # We don't have a remote setup for pushes, so we can't automatically push
          if remote.nil?
            return []
          end
          
          # Hit .git/remotes/$REMOTE/$REF to find out which revision that ref is at.
          push_target.gsub!(/^refs\/heads\//, '')
          r_ref = File.read(File.join(@repo.dir.path, '.git', 'refs', 'remotes', remote, push_target)).strip
          
          # Hit .git/refs/heads/$BRANCH to figure out which revision we're at locally.
          l_ref = File.read(File.join(@repo.dir.path, '.git', 'refs', 'heads', current_branch)).strip
          
          # Check submodules for pushable changes on their current branch
          submodules_commits = cache['submodules'].values.select {|m| not m.unpushed_commits.empty?}.map {|m| Redcar::Scm::ScmMirror::CommitsNode.new m, m.repo.dir.path}
          
          # Hit `git log $R_REV..$L_REV` to get a list of commits that are unpushed.
          if r_ref != l_ref
            submodules_commits + cache['log', r_ref, l_ref].map {|c| Scm::Git::Commit.new(c)}
          else
            submodules_commits + []
          end
        end
        
        # REQUIRED for :push. Pushes all current changesets to the remote
        # repository.
        def push!
          remote = cache['config']['branch.' + current_branch + '.remote']
          push_target = cache['config']['branch.' + current_branch + '.push'] || cache['config']['branch.' + current_branch + '.merge']
          
          # don't block while trying to push changes
          Thread.new do
            repo.push(remote, '+refs/heads/' + current_branch + ':' + push_target)
            
            Redcar.update_gui { cache.refresh; Scm::Manager.refresh_trees }
          end
          
          false # don't refresh trees
        end
      end
    end
  end
end
