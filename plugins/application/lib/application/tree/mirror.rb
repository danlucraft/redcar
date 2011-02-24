
module Redcar
  class Tree
    
    # SPI specification. Implement a class including this module and
    # pass an instance to Tree#new to populate the contents of a Tree.
    module Mirror
      include Redcar::Observable
      
      # Return the title of the tree. It should NOT change.
      #
      # @return [String]
      def title
        "Tree"
      end
      
      # Return the top level entries in the Tree. Each element should
      # be an instance of a class implementing Redcar::Tree::Mirror::NodeMirror
      #
      # @return [Array<NodeMirror>]
      def top
        []
      end
      
      # Does the resource still exist
      #
      # @return [Boolean]
      def exist?
        true
      end
      
      # What type of data does the tree contain? If Node#to_data returns an
      # absolute path to a file, then :file may be specified for OS integration.
      #
      # @return [Symbol] either :file or :text
      def data_type
        :text
      end

      # Has the top nodes changed since the last time `top` 
      # was called?
      #
      # @return [Boolean]
      def changed?
        false
      end
      
      # Should drag and drop be permitted?
      #
      # @return [Boolean]
      def drag_and_drop?
        false
      end
      
      # Create a node from the data created by to_data. This is the reverse
      # operation to #to_data, and should turn the String (in case data_type
      # if :text) or Array of Strings (in case data_type is :file) into an 
      # array of nodes
      #
      # @return [NodeMirror]
      def from_data(data)
        raise "not implemented"
      end
    
      # This must be implemented (along with a from_data method)
      # in order to allow drag and drop and copy and paste within the tree.
      #
      # If the Tree::Mirror data_type is :text (the default), this must
      # return a String. The string should be a *complete* representation
      # of the data in the nodes, so that the from_data method can turn the
      # string back into nodes
      #
      # If the Tree::Mirror data_type is :file, this must return an
      # array of Strings, where each string is the absolute path to the file.
      #
      # @return [String or Array<String>]
      def to_data(nodes)
        raise "not implemented"
      end
      
      # Called when the whole tree needs to be refreshed. Implementations
      # should do whatever they need to do to fetch full tree data, and then
      # yield.
      #
      # The purpose is so that a refresh operation can run against some cached
      # data, but then at the end of the method the mirror can discard the cache.
      # Because refreshes typically generate large numbers of queries.
      def refresh_operation(tree)
        yield
      end
      
      # This is the required interface of a ROW in a TreeView.
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
          nil
        end

        # This node's children
        #
        # @return [Array<NodeMirror>]
        def children
          []
        end

        # Whether this node is a leaf node or not (different to whether or
        # not it has children.)
        #
        # @return [Boolean]
        def leaf?
          true
        end
        
        # The text for the tooltip, or nil if no tooltip
        #
        # @return [String or nil]
        def tooltip_text
          nil
        end
      end
    end
  end
end
