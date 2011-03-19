
module Redcar
  module Scm
    class CommitMirror
      include Redcar::Document::Mirror
      
      def initialize(repo, change=nil)
        @repo = repo
        @change = change
      end
      
      def title
        "Commit message"
      end
      
      def exists?
        true
      end
      
      # Commits don't change till they are commited, at which point
      # they are closed.
      def changed?
        false
      end
      
      def read
        if @change
          @repo.commit_message(@change)
        else
          @repo.commit_message
        end
      end
      
      def commit(contents)
        # filter the contents for comments and generally clean it up
        contents = contents.split("\n").map{|l| l[0,1] == "#" ? "" : l}.join("\n").rstrip
        
        # throw an error if our spring clean left nothing
        raise "Empty commit message. Commit aborted." if contents.empty?
        
        @repo.commit!(contents, @change)
        
        notify_listeners(:change)
      end
      
      class CommitChangesCommand < Command
        sensitize :open_commit_tab
        
        def execute
          tab = Redcar.app.focussed_window.focussed_notebook.focussed_tab
          begin
            doc = tab.edit_view.document
            doc.mirror.commit(doc.to_s)
          rescue
            Application::Dialog.message_box($!.message)
          end
        end
      end
      
      class CreateCommitCommand < Command
        sensitize :open_scm
        
        def execute
          project = Project::Manager.focussed_project
          info = Scm::Manager.project_repositories[project]
          
          Scm::Manager.open_commit_tab(info['repo'])
        end
      end
    end
  end
end
