
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
        
        def activated
          diff = self.diff
          if diff
            # TODO: if we can provide a text diff of ourselves, then display it
          end
        end
        
        def diff
          nil
        end
      end
    end
  end
end
