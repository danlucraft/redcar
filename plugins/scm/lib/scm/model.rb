
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
      
      # REQUIRED to be useful. If no commands are supported, than the SCM will
      # will essentially be useless. These commands loosely translate to the
      # common operations of a distributed CVS. 
      #
      # Supported values to date:
      # :init, :push, :pull, :commit, :switch_branch, :index
      #
      # Note about non-distributed CVS's: If your CVS doesn't support local
      # commits, ie. subversion, then implement :commit and :pull, and then
      # provide translations via the command_names method.
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
          :pull => "Pull Changesets",
          :commit => "Commit Changes",
          :index_add => "Add File",
          :index_ignore => "Ignore File",
          :index_save => "Index Changes",
          :index_unsave => "Revert Index",
          :index_revert => "Revert Changes",
          :index_restore => "Restore File",
          :index_delete => "Mark as Deleted",
          :commitable => "Commit Changes to Subproject",
          :switch_branch => "Switch Branch",
        }
      end
      
      # REQUIRED for :init. Initialise a repository in a given path. 
      # Returns false on error.
      def init!(path)
        raise "Scm.init not implemented." if supported_commands.include?(:init)
        nil
      end
      
      # REQUIRED for :commit. Returns an array of changes currently waiting
      # for commit.
      #
      # @return [Array<Redcar::Scm::ScmMirror::Change>]
      def uncommited_changes
        raise "Scm.uncommited_changes not implemented." if supported_commands.include?(:commit)
        []
      end
      
      # REQUIRED for :commit. Commits the currently staged changes. 
      def commit!(message)
        raise "Scm.commit! not implemented." if supported_commands.include?(:commit)
        nil
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
      
      # REQUIRED for :commitable changes. Commits the currently staged 
      # changes in the subproject.
      def commit!(change, message)
        raise "Scm.commit!(change) not implemented." if supported_commands.include?(:index)
        nil
      end
      
      # REQUIRED for :push. Returns an array of unpushed changesets.
      def unpushed_commits
        raise "Scm.unpushed_commits not implemented." if supported_commands.include?(:push)
        nil
      end
      
      # REQUIRED for :push. Pushes all current changesets to the remote
      # repository.
      def push!
        raise "Scm.push! not implemented." if supported_commands.include?(:push)
        nil
      end
      
      # REQUIRED for :pull. Pulls all remote changesets from the remote
      # repository.
      def pull!
        raise "Scm.pull! not implemented." if supported_commands.include?(:pull)
        nil
      end
      
      # REQUIRED for :switch_branch. Returns an array of branch names.
      def branches
        raise "Scm.branches not implemented." if supported_commands.include?(:switch_branch)
        nil
      end
      
      # REQUIRED for :switch_branch. Switches to the named branch.
      def switch!(branch)
        raise "Scm.switch! not implemented." if supported_commands.include?(:switch_branch)
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
