module Redcar
  class Treebook
    include Redcar::Observable
    include Redcar::Model
    
    attr_reader :trees, :focussed_tree
    
    def initialize
      @trees = []
      @focussed_tree = nil
    end
    
    # Add a tree to this treebook
    #
    # @param [Redcar::Tree]
    def add_tree(tree)
      @trees << tree
      @focussed_tree = tree
      notify_listeners(:tree_added, tree)
    end
    
    # Bring the tree to the front
    #
    # @param [Redcar::Tree]
    def focus_tree(tree)
      @focussed_tree = tree
      notify_listeners(:tree_focussed, tree)
    end
    
    # Remove a tree from this treebook
    #
    # @param [Redcar::Tree]
    def remove_tree(tree)
      if @trees.include?(tree)
        @trees.delete(tree)
        notify_listeners(:tree_removed, tree)
        if tree == focussed_tree
          focus_tree(trees.first) if trees.any?
        end
      end
    end
    
    private
    
    # Tell the Treebook that this tree has been focussed in the GUI.
    def set_focussed_tree(tree)
      @focussed_tree = tree
    end
  end
end
