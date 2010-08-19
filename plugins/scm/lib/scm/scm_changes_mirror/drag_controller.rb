
module Redcar
  module Scm
    class ScmChangesController
      class DragController
        include Redcar::Tree::Controller::DragController
        
        def initialize(tree, repo)
          @tree = tree
          @repo = tree
        end
        
        # Can elements in the tree be reordered by dragging and 
        # dropping? Shows insertion feedback in the GUI.
        def reorderable?
          false
        end
        
        # Called during a drag operation when the cursor hovers over other
        # rows. 
        #
        # @param nodes - the dragged nodes
        # @param target - the hovered over node, or nil if the empty tree area
        # @param position - one of :onto, :before, :after (always :onto unless
        #                   reorderable?)
        def can_drop?(nodes, target, position)
          # We can always attempt to drag anywhere. do_drop handles sanity
          # checking.
          true
        end
        
        # Called when the user has dropped nodes onto another node.
        #
        # @param nodes - the dragged nodes
        # @param target - the hovered over node, or nil if the empty tree area
        # @param position - one of :onto, :before, :after (always :onto unless
        #                   reorderable?)
        def do_drop(nodes, target, position)
          # Make sure we have a target, and that it is a top level item
          target ||= tree.top[1]
          target = type? target
          
          nodes.find_all {|n| target != type?(n)}.each do |n|
            # At this point, we've verified that we're dragging from one node 
            # to another, so just loop through the changes and do the first 
            # action that we can, which will always be the least destructive,
            # ie. will only affect the index.
            
            command = node.status.map {|s| COMMAND_MAP[s]}.flatten.find_all{|s| s != :commit}.first
            
            if command
              repo.method(command).call(n)
            end
          end
        end
        
        private
        
        # Finds the top level item that this node belongs to.
        def type?(node)
          tree.top.each do |top|
            # Make sure we check the top level items themselves too.
            children = top
            
            while children.length > 0
              c = children.shift
              return true if c == node
              children.push(*c.children)
            end
          end
          
          nil
        end
        
      end
    end
  end
end
