
module Redcar
  module Scm
    class ScmMirror
      module Change
        include Redcar::Tree::Mirror::NodeMirror
        
        def text
          path
        end
        
        def icon
          :file
        end
        
        def leaf?
          true
        end
        
        def status
          :new
        end
        
        def path
          ''
        end
      end
    end
  end
end
