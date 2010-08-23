
module Redcar
  module Scm
    class ScmCommitsMirror
      include Redcar::Tree::Mirror
      
      def initialize(repo)
        @repo = repo
      end
      
      def title
        @repo.translations[:unpushed_commits]
      end
      
      def data_type
        :text
      end
      
      def changed?
        @repo.push_targets.count > 0
      end
      
      def drag_and_drop?
        false
      end
      
      def top
        if @repo.push_targets.count > 0
          @repo.push_targets
        else
          @top ||= [ScmCommitsMirror::CommitsNode.new(@repo)]
        end
      end
    end
  end
end
