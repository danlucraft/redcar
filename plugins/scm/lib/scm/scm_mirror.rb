
module Redcar
  module Scm
    class ScmMirror
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
          
          
          
          nodes
        end
      end
    end
  end
end
