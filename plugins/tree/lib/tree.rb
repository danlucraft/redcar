
require 'tree/controller'
require 'tree/mirror'

module Redcar
  class Tree
    include Redcar::Model
    include Redcar::Observable
    include Redcar::HasSPI
    
    attr_reader :tree_mirror, :tree_controller
    
    def initialize(tree_mirror, tree_controller=nil)
      assert_interface(tree_mirror,     Redcar::Tree::Mirror)
      assert_interface(tree_controller, Redcar::Tree::Controller)
      @tree_mirror     = tree_mirror
      @tree_controller = tree_controller
    end
    
    def refresh
      notify_listeners(:refresh)
    end
    
    def edit(element, select_from=nil, select_to=nil)
      notify_listeners(:edit_element, element, select_from, select_to)
    end
    
    def expand(element)
      notify_listeners(:expand_element, element)
    end
    
    def select(element)
      notify_listeners(:select_element, element)
    end
    
    def selection
      controller.selection
    end
  end
end

