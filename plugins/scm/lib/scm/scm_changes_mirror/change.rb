
module Redcar
  module Scm
    class ScmMirror
      module Change
        include Redcar::Tree::Mirror::NodeMirror
        
        #####
        # NodeMirror stuff
        ###
        def text
          path
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
        
        # The status is an array of symbols indicating the status of this change
        # and hence what operations can be performed on it. This is only 
        # consulted if the SCM supports the :index command.
        #
        # Possible values and their implications:
        #   :new - can be passed to index_add, index_ignore
        #   :indexed - can be passed to index_revert, index_unsave
        #   :deleted - can be passed to index_restore, index_unsave
        #   :missing - can be passed to index_restore, index_delete
        #   :changed - can be passed to index_save, index_unsave
        #   :commitable - can be passed to commit!
        #                 Intended to represent subprojects.
        def status
          [:new]
        end
        
        def path
          ''
        end
        
        def diff
          nil
        end
      end
    end
  end
end
