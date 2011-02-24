
module Redcar
  class Tree
    # SPI specification. Implement a class including this module
    # and pass an instance to Tree#new to respond to tree events.
    module Controller
      
      # Called when a node in a tree is activated (e.g double clicked). 
      # ONLY called when that node is a leaf node. If the node is not a 
      # leaf node then the tree will expand the node instead and query
      # for its children.
      def activated(tree, node);   end
      
      # Called when a node in a tree is selected. 
      def selected(tree, node);    end

      # Called when a node in a tree is right clicked on. node may be nil
      # if the right click happened over the tree but not on a node.
      def right_click(tree, node); end
      
      # Called after an edit operation with the new text of the
      # node. See Tree#edit
      def edited(tree, node, text); end
      
      # Called when a drag operation begins. Should return
      # a Redcar::Tree::Controller::DragController.
      def drag_controller(tree)
        DragController::Fake.new
      end
      
      # SPI for Tree drag and drop. Implement this class to support drag and
      # drop in your tree.
      module DragController
        class Fake; include DragController; end

        # Can elements in the tree be reordered by dragging and 
        # dropping? Shows insertion feedback in the GUI.
        def reorderable?
          false
        end
        
        # Called with the dragged nodes when a drag operation begins
        def drag_start(nodes); end
        
        # Called during a drag operation when the cursor hovers over other
        # rows. 
        #
        # @param nodes - the dragged nodes
        # @param target - the hovered over node, or nil if the empty tree area
        # @param position - one of :onto, :before, :after (always :onto unless
        #                   reorderable?)
        def can_drop?(nodes, target, position); end
        
        # Called when the user has dropped nodes onto another node.
        #
        # @param nodes - the dragged nodes
        # @param target - the hovered over node, or nil if the empty tree area
        # @param position - one of :onto, :before, :after (always :onto unless
        #                   reorderable?)
        def do_drop(nodes, target, position); end
      end
    end
  end
end