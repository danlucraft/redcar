$:.push(File.expand_path(File.join(File.dirname(__FILE__), %w{.. vendor})))

require 'java'
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
            :pull, :commit,:index_delete, :index_add,
            :index_ignore ,:index_revert, :index_restore,
            :index_save   ,:index_unsave, :index
          ]
        end

        def pull!(path)
          if repository?(@path)
            client_manager.getUpdateClient().doUpdate(
              Java::JavaIo::File.new(path),
              SVNRevision.HEAD,
              true, # allow unversioned files to exist in directory
              false # store depth in directory
            )
          else
            client_manager.getUpdateClient().doCheckout(
              SVNURL.parseURIEncoded(path),
              Java::JavaIo::File.new(@path),
              SVNRevision.HEAD,
              SVNDepth.INFINITY,
              true # allow unversioned files to exist already in directory
            )
          end
        end

        #TODO: commit! and commit_message
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
          status_client = client_manager.getStatusClient()
          status = status_client.doStatus(Java::JavaIo::File.new(path),false)
          if indexed
            s = case status
            when SVNStatusType::STATUS_MODIFIED then :changed
            when SVNStatusType::STATUS_MISSING  then :missing
            when SVNStatusType::STATUS_DELETED  then :deleted
            when SVNStatusType::STATUS_ADDED    then :indexed
            end
          else
            s = case status
            when SVNStatusType::STATUS_UNVERSIONED then :new
            end
          end
          if s
            children = []
            unless File.file?(path) or not File.exist?(path)
              Dir["#{path.to_s}/*/"].map do |sub_path|
                children = populate_changes(sub_path, indexed) || []
              end
            end
            nodes << Scm::Subversion::Change.new(path,s,children)
          end
          nodes.sort_by {|node| node.path}
        end

        def translations
          if repository?(@path)
            {
              :push => "Commit Changes",
              :pull => "Update Working Copy"
            }
          else
            {
              :push => "Commit Changes",
              :pull => "Checkout Repository"
            }
          end
        end

        def self.debug
          Redcar::Scm::Manager.debug
        end

        def debug
          Redcar::Scm::Subversion::Manager.debug
        end
      end
    end
  end
end