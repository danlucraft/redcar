module Redcar
  class ApplicationSWT
    class Treebook
      
      def initialize(window, model)
        @window, @model = window, model
        add_listeners
        create_tree_view
      end
      
      def add_listeners
        @model.add_listener(:tree_added,   &method(:tree_added))
        @model.add_listener(:tree_removed, &method(:tree_removed))
      end

      def tree_added(tree)
        tree_view = TreeViewSWT.new(@tree_composite, tree)
        tree.controller = tree_view
        title = tree.tree_mirror.title
        @tree_combo.add(title)
        @tree_combo.select(@tree_combo.get_items.to_a.index(title))
        @tree_layout.topControl = tree_view.control
        @tree_composite.layout
      end
      
      def tree_removed(tree)
        tree.controller.close
      end

      def create_tree_view
        @tree_composite = Swt::Widgets::Composite.new(@window.tree_sash, Swt::SWT::NONE)
        @tree_layout = Swt::Custom::StackLayout.new
        @tree_composite.setLayout(@tree_layout)
        
        @tree_combo = Swt::Widgets::Combo.new(@window.left_composite, Swt::SWT::READ_ONLY)
        grid_data = Swt::Layout::GridData.new
        grid_data.grabExcessHorizontalSpace = true
        grid_data.horizontalAlignment = Swt::Layout::GridData::FILL
        grid_data.grabExcessVerticalSpace = false
      	@tree_combo.setLayoutData(grid_data)
        @tree_combo.add_selection_listener do
          selected_tree = @model.trees.detect {|t| t.tree_mirror.title == @tree_combo.text}
          @tree_layout.topControl = selected_tree.controller.control
          @tree_composite.layout
          @tree_combo.select(@tree_combo.get_items.to_a.index(selected_tree.tree_mirror.title))
        end
        
        @tree_composite.layout
        @window.left_composite.layout
      end
      
    end
  end
end

