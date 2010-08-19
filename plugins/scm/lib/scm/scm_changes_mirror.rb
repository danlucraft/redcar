
module Redcar
  module Scm
    class ScmChangesMirror
      include Redcar::Tree::Mirror
      
      def initialize(repo)
        @repo = repo
      end
      
      def title
        "Repository changes"
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
          nodes = []
          
          if @repo.supported_commands.include?(:commit)
            nodes.push(ScmChangesMirror::ChangesNode.new(@repo))
          end
          if @repo.supported_commands.include?(:push)
            nodes.push(ScmCommitsMirror::CommitsNode.new(@repo))
          end
          
          nodes
        end
      end
    end
  end
end
