
require 'java'
require 'scm_svn/change'
require 'redcar-svnkit'
require Redcar::SvnKit.jar_path

module Redcar
  module Scm
    module Subversion
      class Manager
        include Redcar::Scm::Model
        attr_reader :path
        include_package 'org.tmatesoft.svn.core.wc'
        include_package 'org.tmatesoft.svn.core'
        import 'org.tmatesoft.svn.core.internal.io.dav.DAVRepositoryFactory'
        import 'org.tmatesoft.svn.core.internal.io.svn.SVNRepositoryFactoryImpl'
        import 'org.tmatesoft.svn.core.internal.io.fs.FSRepositoryFactory'
        import 'org.tmatesoft.svn.core.io.SVNRepositoryFactory'

        def client_manager
          @manager ||= begin
            m = SVNClientManager.newInstance()
            DAVRepositoryFactory.setup()
            SVNRepositoryFactoryImpl.setup()
            FSRepositoryFactory.setup()
            m
          end
        end

        def repository_type
          "subversion"
        end

        def self.scm_module
          Redcar::Scm::Subversion::Manager
        end

        def self.supported?
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
          cache.refresh
        end

        def cache
          @cache ||= begin
            c = BlockCache.new
          end
        end

        def supported_commands
          [:pull,:commit,:remote_init,:index,:switch_branch,:merge]
        end

        def trunk_path
          if @path.include?('trunk')
            trunk_path = @path[0,@path.index('trunk')] + 'trunk'
          elsif @path.include?('branches')
            trunk_path = @path[0,@path.index('branches')] + 'trunk'
          else
            trunk_path = @path + "/trunk"
          end
          trunk_path if repository?(trunk_path)
        end

        def branch_path
          if trunk_path # no branches without a trunk
            branch_path = trunk_path[0,trunk_path.index('trunk')] +'branches'
          end
          branch_path if branch_path and repository?(branch_path)
        end

        def branches
          if trunk_path
            branch_list = ['trunk']
            if branch_path
              Dir["#{branch_path}/*/"].map do |path|
                branch_list << File.basename(path) if repository?(path)
              end
            end
          else
            branch_list = [File.basename(@path)]
          end
          branch_list
        end

        def current_branch
          branch = File.basename(@path)
          if trunk_path
            if @path.include?(trunk_path) and repository?(trunk_path)
                branch = 'trunk'
            elsif @path.include?(branch_path) and repository?(branch_path)
              Dir["#{branch_path}/*/"].map do |path|
                branch = File.basename(path) if @path.include?(path)
              end
            end
          end
          branch
        end

        def switch!(branch)
          unless current_branch == branch
            if branch == "trunk"
              new_path = trunk_path
            else
              new_path = "#{branch_path}/#{branch}"
            end
            if new_path and File.exist?(new_path)
              window = Redcar.app.windows.detect {|w| w.title == File.basename(new_path)}
              if window
                Redcar.app.set_focussed_window(window)
              else
                Project::DirectoryOpenCommand.new(new_path).run
              end
            else
              Application::Dialog.message_box("Path not found: #{new_path}.")
            end
          end
        end

        def merge!(branch)
          unless current_branch == branch
            if branch == "trunk"
              new_path = trunk_path
            else
              new_path = "#{branch_path}/#{branch}"
            end
            if new_path and File.exist?(new_path)
              client_manager.getDiffClient().doMerge(
                Java::JavaIo::File.new(path), # current branch
                SVNRevision::HEAD,
                Java::JavaIo::File.new(new_path), # other branch
                SVNRevision::HEAD,
                Java::JavaIo::File.new(path), # destination
                SVNDepth::INFINITY,
                true,  # useAncestry - if true then the paths ancestry will be noticed while calculating differences, otherwise not
                false, # force - true to force the operation to run
                false, # dryRun - if true then runs merge without any file changes
                false  # recordOnly - if true, records only the rusult of merge - mergeinfo data
              )
            end
          end
        end

        def pull!(path=nil)
          path = @path if not path
          if repository?(@path)
            client_manager.getUpdateClient().doUpdate(
              Java::JavaIo::File.new(path),
              SVNRevision::HEAD,
              true, # allow unversioned files to exist in directory
              false # store depth in directory
            )
          else
            Application::Dialog.message_box("#{@path} is not a working copy.")
          end
        end

        def remote_init(path,target)
          client_manager.getUpdateClient().doCheckout(
            SVNURL.parseURIEncoded(path),
            Java::JavaIo::File.new(target),
            SVNRevision::HEAD,
            SVNRevision::HEAD,
            SVNDepth::INFINITY,
            true # allow unversioned files to exist already in directory
          )
        end

        def index_add(change)
          client_manager.getWCClient().doAdd(
          Java::JavaIo::File.new(change.path), #wc item file
            false, # if true, this method does not throw exceptions on already-versioned items
            false, # if true, create a directory also at path
            false, # not used; make use of makeParents instead
            SVNDepth::INFINITY, #tree depth
            false, # if true, does not apply ignore patterns to paths being added
            true   # if true, climb upper and schedule also all unversioned paths in the way
          )
          true # refresh tree
        end

        def index_ignore(change)
          ignore_under_path(Java::JavaIo::File.new(File.dirname(change.path)).getAbsolutePath(),File.basename(change.path))
          true # refresh tree
        end

        def index_ignore_all(extension,change)
          ignore_under_path(@path,"*.#{extension}")
          true
        end

        def ignore_under_path(path,pattern)
          dir = Java::JavaIo::File.new(path)
          prop = client_manager.getWCClient().doGetProperty(dir, SVNProperty::IGNORE,
            SVNRevision::BASE, SVNRevision::WORKING)
          if prop and not prop.getValue().toString().strip.empty?
            prop = prop.getValue().toString() + "\n#{pattern}"
          else
            prop = pattern
          end
          client_manager.getWCClient().doSetProperty(dir, SVNProperty::IGNORE,
            SVNPropertyValue.create(prop), false, false, nil)
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
          elsif change.status[0] == :indexed
            index_unsave(change)
            File.delete(File.new(change.path))
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
          if change.status[0] == :unmerged
            resolve_conflict(change)
          end
        end

        def index_restore(change)
          if change.status[0] == :missing
            client_manager.getUpdateClient().doUpdate(
              Java::JavaIo::File.new(change.path),
              SVNRevision::HEAD,
              SVNDepth::INFINITY,
              true,
              false
            )
          end
        end

        def index_unsave(change)
          if change.status[0] == :new
            # Do nothing, there's nothing to unsave
          elsif change.status[0] == :indexed
            index_revert(change)
          else
            Application::Dialog.message_box("#{change.path} is already in the repository. Use 'delete' to remove or revert to cancel local changes.")
          end
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
          nodes.sort_by{|node| node.path}.sort_by do |node|
            if File.directory?(node.path)
              0
            else
              1
            end
          end
        end

        def find_dirs(path,indexed,nodes=[])
          Dir["#{path.to_s}/*/"].map do |a|
            #FIXME: find dirs beneath iff 'a' is not ignored
            status = client_manager.getStatusClient().doStatus(
              Java::JavaIo::File.new(a),false).getContentsStatus()
            find_dirs(a,indexed,nodes) if versioned_statuses.include?(status)
            status = check_file_status(a,indexed)
            if status
              diff_client = client_manager.getDiffClient()
              nodes << Scm::Subversion::Change.new(a,status,[],diff_client)
            end
          end
          check_files(path,indexed,nodes)
        end

        def check_files(path,indexed,nodes)
          files = File.join(path.to_s, "*")
          Dir.glob(files).each do |file_path|
            if File.file?(file_path)
              status = check_file_status(file_path,indexed)
              if status
                diff_client = client_manager.getDiffClient()
                nodes << Scm::Subversion::Change.new(file_path,status,[],diff_client)
              end
            end
          end
        end

        def check_file_status(path,indexed)
          status_client = client_manager.getStatusClient()
          status = status_client.doStatus(Java::JavaIo::File.new(path),false).getContentsStatus()
          if indexed
            s = case status
            when SVNStatusType::STATUS_MODIFIED   then :changed
            when SVNStatusType::STATUS_MISSING    then :missing
            when SVNStatusType::STATUS_DELETED    then :deleted
            when SVNStatusType::STATUS_ADDED      then :indexed
            when SVNStatusType::STATUS_CONFLICTED then :unmerged
            end
            s
          else
            s = case status
            when SVNStatusType::STATUS_UNVERSIONED then :new
            end
            s
          end
        end

        def versioned_statuses
          [
          SVNStatusType::STATUS_MODIFIED,
          SVNStatusType::STATUS_MISSING,
          SVNStatusType::STATUS_DELETED,
          SVNStatusType::STATUS_ADDED,
          SVNStatusType::STATUS_CONFLICTED,
          SVNStatusType::STATUS_NORMAL
          ]
        end

        def resolve_conflict(change)
          client_manager.getWCClient().doResolve(
            Java::JavaIo::File.new(change.path),
            SVNDepth::IMMEDIATES, # change and files beneath
            true, # resolve contents conflict
            true, # resolve property conflict
            true, # resolve tree conflict -- man, I hate those
            SVNConflictChoice.MERGED # choose file as edited and resolved
          )
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
          t[:index_unsave] = "Remove from commit"
          t[:indexed_changes] = "Uncommitted changes"
          t[:unindexed_changes] = "External files"
          t[:remote_init] = "Checkout Subversion Repository"
          t[:push] = "Commit changes",
          t[:pull] = "Update working copy",
          t[:switch_branches] = "Open branch"
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
