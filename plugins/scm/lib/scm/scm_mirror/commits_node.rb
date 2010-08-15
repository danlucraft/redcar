
module Redcar
  module Scm
    class ScmMirror
      class CommitsNode
        include Redcar::Tree::Mirror::NodeMirror
        
        def initialize(repo, text=nil)
          @repo = repo
          @text = text || @repo.translations[:unpushed_commits]
        end
        
        def text
          @text
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
