
module Redcar
  class Tree
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
      
      # Does the resource still exist (e.g. does the dir exist?)
      #
      # @return [Boolean]
      def exist?
        raise "not implemented"
      end
      
      # What type of data does the tree contain? If Node#to_data returns an
      # absolute path to a file, then :file may be specified for OS integration.
      #
      # @return [Symbol] either :file or :text
      def data_type
        raise "not implemented"
      end

      # Has the top nodes changed since the last time `top` 
      # were was called? (E.g. have the contents of the top level dir changed)
      #
      # @return [Boolean]
      def changed?
        raise "not implemented"
      end
      
      # Create a Node from a string created by to_data. See NodeMirror#to_data
      # for details
      #
      # @return [NodeMirror]
      def from_data(string)
        raise "not implemented"
      end
      
      # This is the abstract representation of a ROW in a TreeView.
      module NodeMirror
        include Redcar::Observable
        
        # A complete representation of this node as a string. 
        # This must be implemented (along with a static from_data method)
        # in order to allow drag and drop and copy and paste within the tree.
        #
        # @return [String]
        def to_data
          raise "not implemented"
        end
        
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
