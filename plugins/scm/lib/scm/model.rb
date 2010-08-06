
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
      # :init, :push, :pull, :commit, :switch_branch
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
      def command_names
        {
          :init => "initialise",
          :push => "push",
          :pull => "pull",
          :commit => "commit changes",
          :switch_branch => "switch branch"
        }
      end
      
      # REQUIRED for :init. Attempts to initialise a repository in a given 
      # path. Returns false on error.
      def init!(path)
        raise "Scm.init not implemented." if supported_commands.include?(:init)
        nil
      end
      
      # REQUIRED for :commit. Returns an array of changes currently waiting
      # for commit. 
      def uncommited_changes
        raise "Scm.uncommited_changes not implemented." if supported_commands.include?(:commit)
        []
      end
      
      # REQUIRED for :commit. Attempts to commit the currently staged changes. 
      def commit!
        raise "Scm.commit! not implemented." if supported_commands.include?(:commit)
        nil
      end
      
      # REQUIRED for :push. Returns an array of unpushed changesets.
      def unpushed_commits
        raise "Scm.unpushed_commits not implemented." if supported_commands.include?(:push)
        nil
      end
      
      # REQUIRED for :push. Attempts to push all current changesets.
      def push!
        raise "Scm.push! not implemented." if supported_commands.include?(:push)
        nil
      end
      
      # REQUIRED for :pull. Attempts to pull remote changesets.
      def pull!
        raise "Scm.pull! not implemented." if supported_commands.include?(:pull)
        nil
      end
      
      # REQUIRED for :switch_branch. Returns an array of branch names.
      def branches
        raise "Scm.branches not implemented." if supported_commands.include?(:switch_branch)
        nil
      end
      
      # REQUIRED for :switch_branch. Attempt to switch to the named branch.
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
