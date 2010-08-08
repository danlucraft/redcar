
require 'tree/controller'
require 'tree/mirror'

module Redcar
  # Pass classes implementing Redcar::Tree::Mirror and 
  # Redcar::Tree::Controller to Tree#new to create a tree. Pass to
  # window.treebook.add_tree to open the Tree in a Window.
  #
  # Trees build up their contents by querying the Tree::Mirror. For
  # instance, a simple tree containing the numbers 1 to 10 could be created
  # like this:
  #
  #   class CountMirror 
  #     include Redcar::Tree::Mirror
  #
  #     def top
  #       (1..10).map {|i| CountNode.new(i)}
  #     end
  #
  #     class CountNode
  #       include Redcar::Tree::NodeMirror
  #
  #       def initialize(i)
  #         @i = i
  #       end
  #      
  #       def text
  #         @i.to_s
  #       end
  #     end
  #   end
  #
  #   tree = Tree.new(CountMirror.new)
  #   Redcar.app.focussed_window.treebook.add_tree(tree)
  class Tree
    include Redcar::Model
    include Redcar::Observable
    include Redcar::HasSPI
    
    attr_reader :tree_mirror, :tree_controller
    
    # @param [Tree::Mirror] an instance of a class including Tree::Mirror
    # @param [Tree::Controller] an instance of a class including Tree::Controller
    def initialize(tree_mirror, tree_controller=nil)
      assert_interface(tree_mirror,     Redcar::Tree::Mirror)
      if tree_controller
        assert_interface(tree_controller, Redcar::Tree::Controller)
      end
      @tree_mirror     = tree_mirror
      @tree_controller = tree_controller
    end
    
    # Refresh the tree by requerying the mirror from the top and
    # recursing down through open items.
    def refresh
      notify_listeners(:refresh)
    end
    
    # Begin an edit operation on the node. This allows the user
    # to edit the text. When the user has finished, TreeController#edited
    # will be called with the new text.
    def edit(node, select_from=nil, select_to=nil)
      notify_listeners(:edit_element, node, select_from, select_to)
    end
    
    # Expand the node.
    def expand(node)
      notify_listeners(:expand_element, node)
    end
    
    # Select the node.
    def select(node)
      notify_listeners(:select_element, node)
    end
    
    # @return [Array<NodeMirror>] the selected nodes
    def selection
      controller.selection
    end
    
    # @return [Array<NodeMirror>] the visible nodes
    def visible_nodes
      controller.visible_nodes
    end
  end
end

