
module Redcar
  module Scm
    # This class acts as an interface definition for SCM's.
    # Override as much as possible that is supported by your SCM of choice.
    module Model
      # Returns a string giving the name of the SCM
      def repo_type
        ""
      end
      
      # Checks if a given directory is a repository supported by the SCM
      def repo?(path)
        false
      end
    end
  end
end
