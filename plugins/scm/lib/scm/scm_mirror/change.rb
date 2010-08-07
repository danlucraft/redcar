
module Redcar
  module Scm
    class ScmMirror
      module Change
        include Redcar::Tree::Mirror::NodeMirror
        
        #####
        # NodeMirror stuff
        ###
        def text
          status.to_s + ": " + path
        end
        
        def tooltip_text
          text
        end
        
        def icon
          :file
        end
        
        def leaf?
          true
        end
        
        #####
        # Change definition stuff
        ###
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
