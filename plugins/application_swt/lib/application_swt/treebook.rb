module Redcar
  class ApplicationSWT
    class Treebook
      
      def initialize(composite, layout, model)
        @composite, @layout, @model = composite, layout, model
        add_listeners
      end
      
      def add_listeners
        @model.add_listener(:tree_added,   &method(:tree_added))
        @model.add_listener(:tree_removed, &method(:tree_removed))
      end

      def tree_added(tree)
        create_tree_view(tree)
      end
      
      def tree_removed(tree)
        tree.controller.close
      end

      def create_tree_view(tree)
        tree_view = TreeViewSWT.new(@composite, tree)
        tree.controller = tree_view
        @layout.topControl = tree_view.control
        @composite.layout
      end
      
    end
  end
end

