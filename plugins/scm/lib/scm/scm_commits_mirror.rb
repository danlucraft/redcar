
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
      
      # Root items will never change
      def changed?
        false
      end
      
      def drag_and_drop?
        false
      end
      
      def top
        @top ||= begin
          [ScmCommitsMirror::CommitsNode.new(@repo)]
        end
      end
    end
  end
end
