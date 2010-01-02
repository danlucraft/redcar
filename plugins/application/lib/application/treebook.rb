module Redcar
  class Treebook
    include Redcar::Observable
    include Redcar::Model
    
    attr_reader :trees
    
    def initialize
      @trees = []
    end
    
    # Add a tree to this treebook
    #
    # @param [Redcar::Tree]
    def add_tree(tree)
      @trees << tree
      notify_listeners(:tree_added, tree)
    end
    
    # Remove a tree from this treebook
    #
    # @param [Redcar::Tree]
    def remove_tree(tree)
      if @trees.include?(tree)
        @trees.delete(tree)
        notify_listeners(:tree_removed, tree)
      end
    end
    
    # Refreshes all the trees in the Treebook. (See Tree#refresh).
    def refresh_trees
      @trees.each {|tree| tree.refresh }
    end
  end
end
