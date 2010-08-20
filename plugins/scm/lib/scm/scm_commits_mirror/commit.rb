
module Redcar
  module Scm
    class ScmCommitsMirror
      module Commit
        include Redcar::Tree::Mirror::NodeMirror
        
        def text
          raise "not implemented"
        end
        
        def icon
          File.join(Scm::ICONS_DIR, "notebook--arrow.png")
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
