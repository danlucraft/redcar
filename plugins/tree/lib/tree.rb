
require 'tree/controller'
require 'tree/mirror'

module Redcar
  class Tree
    include Redcar::Model
    
    attr_reader :tree_mirror, :tree_controller
    
    def initialize(tree_mirror, tree_controller=nil)
      @tree_mirror     = tree_mirror
      @tree_controller = tree_controller
    end
  end
end

