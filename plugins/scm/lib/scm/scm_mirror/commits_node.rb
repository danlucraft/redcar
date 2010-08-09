
module Redcar
  module Scm
    class ScmMirror
      class ChangesNode
        include Redcar::Tree::Mirror::NodeMirror
        
        def initialize(repo)
          @repo = repo
        end
        
      end
    end
  end
end
