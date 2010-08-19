
module Redcar
  module Scm
    class ScmChangesMirror
      class ChangesNode
        include Redcar::Tree::Mirror::NodeMirror
        
        def initialize(repo)
          @repo = repo
        end
        
        def text
          @repo.translations[:uncommited_changes]
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
