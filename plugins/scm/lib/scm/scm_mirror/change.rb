
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
        #   :missing - can be passed to index_revert, index_delete
        #   :changed - can be passed to index_save, index_unsave
        def status
          [:new]
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
