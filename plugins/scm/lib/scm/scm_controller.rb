
module Redcar
  module Scm
    class ScmController
      include Redcar::Tree::Controller
      
      # Ignore all interaction!
      def activated(tree, node)
        
      end
    end
  end
end
