
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
        # submenus and snippets can't go above or below the bundle
        return false if position != :onto and target.is_a?(BundleNode)
        true
      end

      def do_drop(nodes, target, position)
        bundle = nodes.first.bundle
        uuids  = nodes.map {|n| n.uuid}
        # remove nodes from their parent nodes
        nodes.each do |node|
          node.parent.children.reject! {|n| n.uuid == node.uuid}
          case node.parent
          when BundleNode
            bundle.main_menu['items'].reject! {|id| id == node.uuid}
          when SnippetGroup
            bundle.sub_menus[node.parent.uuid]['items'].reject! {|id| id == node.uuid}
          end
        end
        # if the nodes are going above or below
        # the target, the *real* target is the node's parent
        if position != :onto
          insert_index = target.parent.children.index(target)
          insert_index += 1 if position == :after
          target = target.parent
        end
        # attach nodes to their new parent
        nodes.each {|n| n.parent = target }
        case target
        when BundleNode
          if insert_index
            target.children = target.children.insert(insert_index,nodes).flatten
            bundle.main_menu['items'] = bundle.main_menu['items'].insert(insert_index,uuids).flatten
          else
            target.children = nodes + target.children
            bundle.main_menu['items'] = uuids + bundle.main_menu['items']
          end
        when SnippetGroup
          menu = bundle.sub_menus[target.uuid]['items']
          if insert_index
            target.children = target.children.insert(insert_index,nodes).flatten
            bundle.sub_menus[target.uuid]['items'] = menu.insert(insert_index, uuids).flatten
          else
            target.children = nodes + target.children
            bundle.sub_menus[target.uuid]['items'] = uuids + menu
          end
        end
        Textmate::BundleEditor.write_bundle(bundle)
        Textmate::BundleEditor.reload_cache
        @tree.refresh
      end
    end
  end
end