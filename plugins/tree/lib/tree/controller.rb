
module Redcar
  class Tree
    # Abstract interface. The Controller's methods are called when the Tree's
    # rows are activated.
    module Controller
      def activated(node)
        raise "not implemented"
      end
    end
  end
end