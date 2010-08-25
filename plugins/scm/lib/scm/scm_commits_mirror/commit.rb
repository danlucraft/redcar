
module Redcar
  module Scm
    class ScmCommitsMirror
      module Commit
        include Redcar::Tree::Mirror::NodeMirror
        
        def text
          raise "not implemented"
        end
        
        def icon
          :"notebook--arrow"
        end
        
        def leaf?
          true
        end
        
        def log
          nil
        end
      end
    end
  end
end
