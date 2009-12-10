
module Redcar
  class TreeView
    # Abstract interface. A Mirror allows an TreeView contents to reflect 
    # some other resource, for example a directory tree on disk.
    # They have methods for loading the contents from the resource.
    #
    # Events: changed
    module Mirror
      include Redcar::Observable
      
      # Return the title of the resource. (e.g. the name of the directory)
      #
      # @return [String]
      def title
        raise "not implemented"
      end
      
      # Return the top entries in the Tree. (e.g. the files in the top dir)
      #
      # @return [Array<NodeMirror>]
      def top
        raise "not implemented"
      end

      # Has the top nodes changed since the last time `top` 
      # were was called? (E.g. have the contents of the top level dir changed)
      #
      # @return [Boolean]
      def changed?
        raise "not implemented"
      end
      
      # This is the abstract representation of a ROW in a TreeView.
      module NodeMirror
        include Redcar::Observable
        
        # Which text to show in the tree
        #
        # @return [String]
        def text
          raise "not implemented"
        end
        
        # Which icon to show next to the text
        def icon
          raise "not implemented"
        end

        # This node's children
        #
        # @return [Array<NodeMirror>]
        def children
          raise "not implemented"
        end

        # Whether this node is a leaf node or not (different to whether or
        # not it has children.)
        #
        # @return [Boolean]
        def leaf?
          raise "not implemented"
        end
      end
    end
  end
end
