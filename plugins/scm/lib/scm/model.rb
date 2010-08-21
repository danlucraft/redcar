
module Redcar
  module Scm
    # This class acts as an interface definition for SCM's.
    # Override as much as possible that is supported by your SCM of choice.
    module Model
      # Returns a string giving the name of the SCM
      def repository_type
        ""
      end
      
      # REQUIRED. Checks if a given directory is a repository supported by 
      # the SCM.
      def repository?(path)
        raise "Scm.repository? not implemented."
      end
      
      # REQUIRED. Initialises the SCM with a path. This path should be used
      # for all future interactions. Repeated calls to load should be treated
      # as a breaking error.
      def load(path)
        raise "Scm.load not implemented."
      end
      
      # RECOMMENDED. If we call this method, than we expect the repository to
      # return all fresh data for any subsequent calls. Any caching should be
      # reset.
      def refresh
        nil
      end
      
      # REQUIRED to be useful. If no commands are supported, than the SCM will
      # will essentially be useless. These commands loosely translate to the
      # common operations of a distributed CVS. 
      #
      # Supported values to date:
      #  * :init
      #  * :push
      #  * :pull
      #  * :pull_targetted
      #  * :commit
      #  * :index
      #  * :switch_branch
      #  * :merge
      #
      # Note about non-distributed CVS's: If your CVS doesn't support local
      # commits, ie. subversion, then implement :commit and :pull, and then
      # provide translations via the translations method.
      def supported_commands
        []
      end
      
      # This method allows SCM's to override the default names for different
      # commands and bring them into line with the normal vocabulary in their
      # respective worlds. ie, SVN calls :commit and :pull "checkin" and 
      # "checkout" respectively. If you overload this method, you need to
      # provide names for all commands you support with supported_commands
      def translations
        {
          :init => "Initialise " + repository_type.capitalize,
          :push => "Push Changesets",
          :unpushed_commits => "Unpushed commits",
          :pull => "Pull Changesets",
          :pull_targetted => "Pull...",
          :commit => "Commit Changes",
          :uncommited_changes => "Uncommited changes",
          :indexed_changes => "Indexed changes",
          :unindexed_changes => "Unindexed changes",
          :index_add => "Add File",
          :index_ignore => "Ignore File",
          :index_save => "Index Changes",
          :index_unsave => "Revert Index",
          :index_revert => "Revert Changes",
          :index_restore => "Restore File",
          :index_delete => "Mark as Deleted",
          :commitable => "Commit Changes to Subproject",
          :switch_branch => "Switch Branch",
          :merge => "Merge...",
        }
      end
      
      # REQUIRED for :init. Initialise a repository in a given path. 
      # Returns false on error.
      def init!(path)
        raise "Scm.init not implemented." if supported_commands.include?(:init)
        nil
      end
      
      # REQUIRED for :commit if :index is not supported. Returns an 
      # array of changes currently waiting for commit.
      #
      # @return [Array<Redcar::Scm::ScmChangesMirror::Change>]
      def uncommited_changes
        raise "Scm.uncommited_changes not implemented." if supported_commands.include?(:commit)
        []
      end
      
      # REQUIRED for :commit if :index is supported. Returns an array
      # of changes currently in the index.
      #
      # @return [Array<Redcar::Scm::ScmChangesMirror::Change>]
      def indexed_changes
        raise "Scm.indexed_changes not implemented." if supported_commands.include?(:commit)
        []
      end
      
      # REQUIRED for :commit if :index is supported. Returns an array
      # of changes currently not in the index.
      #
      # @return [Array<Redcar::Scm::ScmChangesMirror::Change>]
      def unindexed_changes
        raise "Scm.unindexed_changes not implemented." if supported_commands.include?(:commit)
        []
      end
      
      # REQUIRED for :index. Adds a new file to the index.
      def index_add(change)
        raise "Scm.index_add not implemented" if supported_commands.include?(:index)
        nil
      end
      
      # REQUIRED for :index. Ignores a new file so it won't show in changes.
      def index_ignore(change)
        raise "Scm.index_ignore not implemented" if supported_commands.include?(:index)
        nil
      end
      
      # REQUIRED for :index. Reverts a file to its last commited state.
      def index_revert(change)
        raise "Scm.index_revert not implemented" if supported_commands.include?(:index)
        nil
      end
      
      # REQUIRED for :index. Reverts a file in the index back to it's 
      # last commited state, but leaves the file intact.
      def index_unsave(change)
        raise "Scm.index_unsave not implemented" if supported_commands.include?(:index)
        nil
      end
      
      # REQUIRED for :index. Saves changes made to a file in the index.
      def index_save(change)
        raise "Scm.index_save not implemented" if supported_commands.include?(:index)
        nil
      end
      
      # REQUIRED for :index. Restores a file to the last known state of
      # the file. This may be from the index, or the last commit.
      def index_restore(change)
        raise "Scm.index_restore not implemented" if supported_commands.include?(:index)
        nil
      end
      
      # REQUIRED for :index. Marks a file as deleted in the index.
      def index_delete(change)
        raise "Scm.index_delete not implemented" if supported_commands.include?(:index)
        nil
      end
      
      # REQUIRED for :commit. Commits the currently indexed changes 
      # in the subproject.
      #
      # @param change Required for :commitable changes. Ignore if
      # you don't provide these.
      def commit!(message, change=nil)
        raise "Scm.commit! not implemented." if supported_commands.include?(:index)
        nil
      end
      
      # REQUIRED for :commit. Gets a default commit message for the 
      # currently indexed changes.
      #
      # @param change Required for :commitable changes. Ignore if
      # you don't provide these.
      def commit_message(change=nil)
        "\n\n# Please enter your commit message above."
      end
      
      # REQUIRED for :push. Returns an array of unpushed changesets for
      # a given target.
      #
      # @return [Array<Redcar::Scm::ScmCommitsMirror::Commit>]
      def unpushed_commits(target='')
        raise "Scm.unpushed_commits not implemented." if supported_commands.include?(:push)
        nil
      end
      
      # REQUIRED for :push. Pushes all current changesets to the remote
      # repository for the given target only.
      def push!(target='')
        raise "Scm.push! not implemented." if supported_commands.include?(:push)
        nil
      end
      
      # RECOMMENDED for :push. Allows to provide a list of targets that
      # can be pushed.
      def push_targets
        []
      end
      
      # REQUIRED for :pull and :pull_targetted. Pulls all remote changesets from the 
      # remote repository.
      # 
      # Note: If you only support :pull, you can implement this without the
      # argument. It will never be called with an explicit nil.
      def pull!(remote=nil)
        raise "Scm.pull! not implemented." if supported_commands.include?(:pull)
        nil
      end
      
      # REQUIRED for :pull_targetted. Returns an array of pull targets.
      def pull_targets
        raise "Scm.pull_targets not implemented." if supported_commands.include?(:pull_targeted)
        []
      end
      
      # REQUIRED for :switch_branch and :merge. Returns an array of branch names.
      #
      # @return [Array<String>]
      def branches
        raise "Scm.branches not implemented." if supported_commands.include?(:switch_branch) or supported_commands.include?(:merge)
        []
      end
      
      # REQUIRED for :switch_branch. Returns the name of the current branch.
      def current_branch
        raise "Scm.current_branch not implemented." if supported_commands.include?(:switch_branch)
        ''
      end
      
      # REQUIRED for :switch_branch. Switches to the named branch.
      def switch!(branch)
        raise "Scm.switch! not implemented." if supported_commands.include?(:switch_branch)
        nil
      end
      
      # REQUIRED for :merge. Merges the target branch with the current one.
      def merge!(branch)
        raise "Scm.switch! not implemented." if supported_commands.include?(:merge)
        nil
      end
      
      # Allows the SCM to provide a custom adapter which is injected into the
      # project instead of old_adapter. This allows interception of file 
      # modifications such as move and copy, which you may wish to do via
      # your SCM instead of normal file system operations.
      def adapter(old_adapter)
        nil
      end
    end
  end
end
