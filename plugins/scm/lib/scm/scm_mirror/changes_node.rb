
module Redcar
  module Scm
    class ScmMirror
      class ChangesNode
        include Redcar::Tree::Mirror::NodeMirror
        
        def initialize(repo)
          @repo = repo
        end
        
        def text
          "Uncommited changes"
        end
        
        def icon
          :directory
        end
        
        def leaf?
          false
        end
        
        def children
          @repo.uncommited_changes
        end
      end
    end
  end
end
