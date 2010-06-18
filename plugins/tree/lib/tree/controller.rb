
module Redcar
  class Tree
    # SPI specification
    module Controller
      
      # Called with the node that was activated.
      def activated(node);   end
      
      # Called with the node that was right clicked on
      def right_click(node); end

      # Called when a drag operation begins. Should return
      # a Redcar::Tree::Controller::DragController.
      def drag_controller(tree)
        DragController::Fake.new
      end
      
      # SPI for Tree drag and drop
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