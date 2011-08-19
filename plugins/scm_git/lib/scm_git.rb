
# Don't error if we don't have git installed
begin
  gem "git"
  require 'git'
rescue
end

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
          begin
            if ::Git::Lib.new.meets_required_version?
              return true
            end
          rescue
            puts $!.class.name + ": " + $!.message
          end
          false
        end

        # Whether to print debugging messages. Default to whatever scm is using.
        def self.debug
          Redcar::Scm::Manager.debug
        end

        def debug
          Redcar::Scm::Git::Manager.debug
        end

        def from_data(data)
          data = data.split(':')
          file = ::Git::Status::StatusFile.new(nil, {
            :type_raw => data[0],
            :path => data[1],
          })
          repo = Scm::Git::Manager.new.load(data[2])
          Scm::Git::Change.new(file, repo, :file, data[4] == "true")
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
              ref_path = File.join(@repo.dir.path, '.git', 'refs', 'heads');
              head = File.read(File.join(@repo.dir.path, '.git', 'HEAD')).strip
              branch_globs = Dir.glob(File.join(ref_path, '*'))
              branches = []

              while branch = branch_globs.shift
                if File.directory?(branch)
                  branch_globs.push(*Dir.glob(File.join(branch, '*')))
                else
                  branches.push branch
                end
              end

              branches.map {|b|
                b[ref_path.length + 1, b.length - ref_path.length - 1]
              }.map {|b|
                [b, ('ref: refs/heads/' + b == head)]
              }
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
                  path = File.join(@repo.dir.path, v['path'])
                  if File.exist?(File.join(path, '.git'))
                    mod = Scm::Git::Manager.new
                    mod.load(path)
                    mods[v['path']] = mod
                  end
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
        attr_reader :repo, :path

        def repository_type
          "git"
        end

        def repository?(path)
          return true if repository_path(path)
        end

        def repository_path(path)
          if File.exist?(File.join(path, %w{.git}))
            return path
          else
            unless path == File.dirname(path)
              repository_path(File.dirname(path))
            end
          end
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
          @repo = ::Git.open(repository_path(path))
          @path = path
          cache.refresh
          self
        end

        # Not used by scm, but we do use this internally.
        def uncommited_changes
          indexed_changes + unindexed_changes
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

        CHANGE_PRIORITIES = {:sub_project => 0, :directory => 1, :file => 2}

        def prepare_changes(indexed)
          changes = cache['submodules'].find_all do |k,s|
            s.uncommited_changes.length > 0
          end.map do |k,s|
            file = ::Git::Status::StatusFile.new(nil, {
              :path => k,
              :type => "M",
              :type_raw => "MM"
            })
            [k, file]
          end

          changes += cache['status'].all_changes.find_all {|c| not changes.find{|d| c[0] == d[0]}}

          # f[0] is the path, and f[1] is the actual StatusFile
          changes.find_all {|c| valid_change?(c[1].type_raw, indexed)}.map do |f|
            full_path = File.join(@repo.dir.path, f[0])
            type = (((not File.exist?(full_path)) or File.file?(full_path)) ? :file : :directory)

            if type == :directory and cache['submodules'][f[0]]
              type = :sub_project
            end

            if type == :sub_project
              submodule = cache['submodules'][f[0]]
              Scm::Git::Change.new(
                f[1], self, type, indexed,
                indexed ? submodule.indexed_changes : submodule.unindexed_changes
              )
            else
              Scm::Git::Change.new(f[1], self, type, indexed)
            end
          end.sort_by {|m| m.path}.sort_by {|m| CHANGE_PRIORITIES[m.type]}
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
            return change.repo.index_ignore(change)
          end

          add_to_gitignore(change.path)

          cache.refresh
          true # refresh trees
        end

        # REQUIRED for :index. Ignores all files with a certain extension so they
        # won't show in changes.
        def index_ignore_all(extension, change)
          # delegate to the proper submodule
          if self != change.repo
            return change.repo.index_ignore(change)
          end

          add_to_gitignore("*." + extension)

          cache.refresh
          true # refresh trees
        end

        private

        def add_to_gitignore(line)
          gitignore = File.join(repo.dir.path, '.gitignore')
          if not File.exist? gitignore
            File.new(gitignore, "w").close
          end
          gitignore = File.new(gitignore, 'r+')

          # Make sure there's data in the file, otherwise we can't seek.
          if File.size(gitignore) > 0
            # Check the last byte of the file for a newline
            gitignore.seek(-1, IO::SEEK_END)
              if gitignore.sysread(1) != "\n"
              gitignore.syswrite("\n")
            end
          end

          gitignore.syswrite(line + "\n")
          gitignore.close
        end

        public

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
          if change.git_status[0,1] == 'A' or change.git_status[0,1] == '?'
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

          @repo.reset('HEAD', :file => change.path)

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

          if change.git_status[1,1] == '?'
            FileUtils.rm(File.join(@repo.dir.path, change.path))
          else
            @repo.remove(change.path)
          end
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
          branch_list = cache['branches'].map {|b| b[0]}
          branch_list + ['New...']
        end

        # REQUIRED for :switch_branch. Returns the name of the current branch.
        def current_branch
          b = cache['branches'].select { |b| b[1] }.first

          b.nil? ? "" : b[0]
        end

        # REQUIRED for :switch_branch. Switches to the named branch.
        def switch!(branch)
          if branch == 'New...'
            result = Application::Dialog.input("New Branch Name",
              "Please enter a new branch name","")
            if value = result[:value] and value != ""
              newbranch = value
              begin
                @repo.branch(newbranch).checkout
              rescue Object => e
                Application::Dialog.message_box(e.to_s)
                e.backtrace.each {|line| p line}
              end
            end
          else
            @repo.checkout(branch)
          end
          cache.refresh
        end

        def push_targets
          targets = branches.map {|b| Scm::ScmCommitsMirror::CommitsNode.new(self, b)}
          modules = cache['submodules'].clone

          while m = modules.shift
            path = m[0]
            m[1].cache['submodules'].each {|k,v| modules[File.join(path, k)] = v}

            targets += m[1].branches.map {|b| Scm::ScmCommitsMirror::CommitsNode.new(m[1], b, "#{b} (#{path})")}
          end

          # only return targets we can actually push to
          targets.find_all do |t|
            remote = t.repo.cache['config']['branch.' + t.branch + '.remote']

            if remote
              push_target = t.repo.cache['config']['branch.' + t.branch + '.push'] || t.repo.cache['config']['branch.' + t.branch + '.merge']

              push_target.gsub!(/^refs\/heads\//, '')
              r_ref_file = File.join(t.repo.repo.dir.path, '.git', 'refs', 'remotes', remote, push_target)

              File.exist?(r_ref_file)
            end
          end
        end

        # REQUIRED for :push. Returns an array of unpushed changesets.
        #
        # @return [Array<Redcar::Scm::ScmMirror::Commit>]
        def unpushed_commits(branch=current_branch)
          # Hit `git config -l` to figure out which remote/ref this branch uses for pushing.
          remote = cache['config']['branch.' + branch + '.remote']
          push_target = cache['config']['branch.' + branch + '.push'] || cache['config']['branch.' + branch + '.merge']

          # We don't have a remote setup for pushes, so we can't automatically push
          return [] if remote.nil?

          # Hit .git/remotes/$REMOTE/$REF to find out which revision that ref is at.
          push_target.gsub!(/^refs\/heads\//, '')
          r_ref_file = File.join(@repo.dir.path, '.git', 'refs', 'remotes', remote, push_target)
          return [] if not File.exist?(r_ref_file)
          r_ref = File.read(r_ref_file).strip

          # Hit .git/refs/heads/$BRANCH to figure out which revision we're at locally.
          l_ref = File.read(File.join(@repo.dir.path, '.git', 'refs', 'heads', branch)).strip

          # Hit `git log $R_REV..$L_REV` to get a list of commits that are unpushed.
          if r_ref != l_ref
            cache['log', r_ref, l_ref].map {|c| Scm::Git::Commit.new(c)}
          else
            []
          end
        end

        # REQUIRED for :push. Pushes all current changesets to the remote
        # repository.
        def push!(branch=current_branch)
          remote = cache['config']['branch.' + branch + '.remote']
          push_target = cache['config']['branch.' + branch + '.push'] || cache['config']['branch.' + branch + '.merge']

          # don't block while trying to push changes
          Thread.new do
            repo.push(remote, '+refs/heads/' + branch + ':' + push_target)

            Redcar.update_gui { cache.refresh; Scm::Manager.refresh_trees }
          end

          false # don't refresh trees
        end
      end
    end
  end
end
