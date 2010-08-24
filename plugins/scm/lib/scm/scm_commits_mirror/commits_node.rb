
module Redcar
  module Scm
    class ScmCommitsMirror
      class CommitsNode
        include Redcar::Tree::Mirror::NodeMirror
        
        attr_reader :repo, :branch
        
        def initialize(repo, branch=nil, text=nil)
          @repo = repo
          @branch = branch
          @text = text || branch || @repo.translations[:unpushed_commits]
        end
        
        def text
          @text
        end
        
        def icon
          :"folder--arrow"
        end
        
        def leaf?
          false
        end
        
        def children
          if branch
            @repo.unpushed_commits(branch)
          else
            @repo.unpushed_commits
          end
        end
      end
    end
  end
end
