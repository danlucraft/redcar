
module Redcar
  module Textmate
    class DragController

      def initialize(tree)
        @tree = tree
      end

      def reorderable?
        true
      end

      def drag_start(nodes); end

      # nodes    - the selected tree nodes
      # target   - the location onto which the nodes will be dropped; either a node or nil
      # position - :before, :after, or :onto
      def can_drop?(nodes, target, position)
        # must drop nodes into a bundle
        return false if target.nil?
        # can't drop nodes onto themselves or drag the bundle
        return false if nodes.detect {|n| n == target || n.is_a?(BundleNode)}
        # all nodes must in the same bundle (for now anyway)
        return false if nodes.detect {|n| n.bundle != target.bundle }
        # nodes can't go into a snippet node
        return false if position == :onto and target.is_a?(SnippetNode)
        # submenus and snippets can't go above the bundle
        return false if position == :before and target.is_a?(BundleNode)
        true
      end

      def do_drop(nodes, target, position)
        # remove nodes from their parent nodes
        case target
        when BundleNode # (one option)
          # insert nodes immediately after the bundle node, as children
        when SnippetGroup # (three options)
          # insert nodes above or below (attach to parent), or as children
        when SnippetNode # (two options)
          # insert nodes above or below the snippet, adding children to
          # the snippets's parent
        end
      end
    end
  end
end