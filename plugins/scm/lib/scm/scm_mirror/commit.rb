
module Redcar
  module Scm
    class ScmMirror
      module Change
        include Redcar::Tree::Mirror::NodeMirror
        
        def text
          raise "not implemented"
        end
        
        def icon
          :file
        end
        
        def leaf?
          true
        end
      end
    end
  end
end
