
module Redcar
  module Scm
    class ScmMirror
      class CommitsNode
        include Redcar::Tree::Mirror::NodeMirror
        
        def initialize(repo)
          @repo = repo
        end
        
        def text
          @repo.translations[:unpushed_commits]
        end
        
        def icon
          :directory
        end
        
        def leaf?
          false
        end
        
        def children
          @repo.unpushed_commits
        end
      end
    end
  end
end
