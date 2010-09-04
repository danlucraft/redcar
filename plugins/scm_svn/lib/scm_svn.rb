$:.push(File.expand_path(File.join(File.dirname(__FILE__), %w{.. vendor})))

require 'java'
require 'scm_svn/change'
begin
  require 'svnkit.jar'
rescue
  #Subversion Libraries not found
end

module Redcar
  module Scm
    module Subversion
      class Manager
        include Redcar::Scm::Model
        include_package 'org.tmatesoft.svn.core.wc'
        import 'org.tmatesoft.svn.core.SVNURL'
        import 'org.tmatesoft.svn.core.SVNDepth'

        def client_manager
          @manager ||= SVNClientManager.newInstance()
        end

        def repository_type
          "subversion"
        end

        def self.scm_module
          Redcar::Scm::Subversion::Manager
        end

        def self.supported?
          puts "    Subversion support is currently in progress" if debug
          true
        end

        def load(path)
          raise "Already loaded repository" if @path
          @path = path
        end

        def repository?(path)
          File.exist?(File.join(path, %w{.svn}))
        end

        def refresh
        end

        def supported_commands
          [
            :pull,:commit ,:index_delete, :index_add,
            :index_ignore ,:index_revert, :index_save,
            :index_unsave ,:index
          ]
        end

        def pull!(path=nil)
          if repository?(@path)
            client_manager.getUpdateClient().doUpdate(
              Java::JavaIo::File.new(path),
              SVNRevision::HEAD,
              true, # allow unversioned files to exist in directory
              false # store depth in directory
            )
          else
            client_manager.getUpdateClient().doCheckout(
              SVNURL.parseURIEncoded(path),
              Java::JavaIo::File.new(@path),
              SVNRevision::HEAD,
              SVNDepth::INFINITY,
              true # allow unversioned files to exist already in directory
            )
          end
        end

        def index_add(change)
          client_manager.getWCClient().doAdd(
                    Java::JavaIo::File.new(change.path), #wc item file
                    false, # if true, this method does not throw exceptions on already-versioned items
                    false, # if true, create a directory also at path
                    false, # not used; make use of makeParents instead
                    SVNDepth::INFINITY, #tree depth
                    false, # if true, does not apply ignore patterns to paths being added
                    true)  # if true, climb upper and schedule also all unversioned paths in the way
          true # refresh tree
        end

        def index_ignore(change)
          status = client_manager.getStatusClient().doStatus(
                        Java::JavaIo::File.new(change.path),
                        false) #don't use remote
                        status.setContentsStatus(SVNStatusType::STATUS_IGNORED)
          true # refresh tree
        end

        def index_revert(change)
          change_lists = Java::JavaUtil::ArrayList.new
          client_manager.getWCClient().doRevert(
            [Java::JavaIo::File.new(change.path)].to_java(Java::JavaIo::File),
            SVNDepth::INFINITY,
            change_lists # might be useful later
          )
          true # refresh tree
        end

        def index_delete(change)
          if change.status[0] == :new
            File.delete(change.path)
          elsif change.status[0] == :added
            index_unsave(change)
            File.delete(Fle.new(change.path))
          else
            client_manager.getWCClient().doDelete(
            Java::JavaIo::File.new(change.path),
              false, # true to force operation to run
              false, # true to delete files from filesystem
              false  # true to do a dry run
            )
          end
        end

        def index_save(change)
          #TODO: what to do here? Maybe cache?
        end

        def index_restore(change)
          #TODO: restore saved index
        end

        def index_unsave(change)
          if change.status[0] == :new
            # Do nothing, there's nothing to unsave
          elsif change.status[0] == :added
            status = client_manager.getStatusClient().doStatus(Java::JavaIo::File.new(change.path))
            status.setContentsStatus(SVNStatusType::STATUS_UNVERSIONED)
          else
            Application::Dialog.message_box("#{change.path} is already in the repository. Use 'delete' to remove.")
          end
          true # refresh tree
        end

        def commit!(message,change=nil)
          committer = client_manager.getCommitClient()
          if change
            paths = [Java::JavaIo::File.new(change.path)]
          else
            paths = []
            indexed_changes.each { |c| paths << Java::JavaIo::File.new(c.path) }
          end
          packet = committer.doCollectCommitItems(
                    paths.to_java(Java::JavaIo::File),
                    true,  # keep locks
                    false, # true to force
                    SVNDepth::INFINITY, # tree depth
                    [].to_java(:string) # changelist names array
                   )
          idx = message.index(log_divider_message)
          message = message[0,idx] if idx
          committer.doCommit(packet, true, message)
          true
        end

        def commit_message(change=nil)
          msg = "\n\n#{log_divider_message}\n\n"
          if change
            msg << change.log_status + "\n"
          else
            indexed_changes.each do |c|
              msg << c.log_status + "\n"
            end
          end
          msg
        end

        def log_divider_message
          "--This line, and those below, will be ignored--"
        end

        def uncommited_changes
          indexed_changes + unindexed_changes
        end

        def unindexed_changes
          populate_changes(@path,false)
        end

        def indexed_changes
          populate_changes(@path,true)
        end

        def populate_changes(path,indexed)
          nodes = []
          find_dirs(path,indexed,nodes)
          nodes
        end

        def find_dirs(path,indexed,nodes=[])
          Dir["#{path.to_s}/*/"].map do |a|
            find_dirs(a,indexed,nodes)
          end
          check_files(path,indexed,nodes)
        end

        def check_files(path,indexed,nodes)
          files = File.join(path.to_s, "*")
          Dir.glob(files).each do |file_path|
            if File.file?(file_path)
              status = check_file_status(file_path,indexed)
              if status
                diff = file_diff(file_path) unless status == :new
                nodes << Scm::Subversion::Change.new(file_path,status,[],diff)
              end
            end
          end
        end

        def check_file_status(path,indexed)
          status_client = client_manager.getStatusClient()
          status = status_client.doStatus(Java::JavaIo::File.new(path),false).getContentsStatus()
          if indexed
            s = case status
            when SVNStatusType::STATUS_MODIFIED then :changed
            when SVNStatusType::STATUS_MISSING  then :missing
            when SVNStatusType::STATUS_DELETED  then :deleted
            when SVNStatusType::STATUS_ADDED    then :indexed
            end
            s
          else
            s = case status
            when SVNStatusType::STATUS_UNVERSIONED then :new
            end
            s
          end
        end

        def file_diff(path)
          differ = client_manager.getDiffClient()
          stream = Java::JavaIo::ByteArrayOutputStream.new
          file   = Java::JavaIo::File.new(path)
          change_lists = Java::JavaUtil::ArrayList.new
          differ.doDiff(file, SVNRevision::BASE,
                        file, SVNRevision::WORKING,
                        SVNDepth::IMMEDIATES,
                        false,
                        stream,
                        change_lists)
          stream.toString()
        end

        def translations
          t = super
          if repository?(@path)
            t[:push] = "Commit Changes",
            t[:pull] = "Update Working Copy"
          else
            t[:push] = "Commit Changes",
            t[:pull] = "Checkout Repository"
          end
          t
        end

        def self.debug
          Redcar::Scm::Manager.debug
        end

        def debug
          Redcar::Scm::Subversion::Manager.debug
        end

        def inspect
          if @path
            %Q{#<Scm::Subversion::Manager "#{@path}">}
          else
            %Q{#<Scm::Subversion::Manager>}
          end
        end
      end
    end
  end
end