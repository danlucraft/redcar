require 'swt/vtab_folder'
require 'swt/vtab_item'

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
        @model.add_listener(:tree_focussed, &method(:tree_focussed))
      end

      def tree_added(tree)
        i = Swt::Widgets::VTabItem.new(@treebook, Swt::SWT::NULL)
        i.text = tree.tree_mirror.title
        i.control = TreeViewSWT.new(@treebook, tree)
        tree.controller = i.control
        @treebook.silent_selection(i)
      end

      def tree_removed(tree)
        tree.controller.close
        @treebook.remove_item(@treebook.get_item(tree.tree_mirror.title))
      end

      def tree_focussed(tree)
        item = @treebook.get_item(tree.tree_mirror.title)
        @treebook.silent_selection(item)
      end

      def create_tree_view
        @treebook = Swt::Widgets::VTabFolder.new(@window.tree_sash, Swt::SWT::NONE)
        colors = [ Swt::Graphics::Color.new(display, 230, 240, 255),
          Swt::Graphics::Color.new(display, 170, 199, 246),
          Swt::Graphics::Color.new(display, 135, 178, 247) ]
        percents = [60, 85]
        @treebook.set_selection_background(colors, percents, true)

        @treebook.add_selection_listener do |event|
          selected_tree = event.item.control
          @model.focus_tree(selected_tree)
        end

        @treebook.layout
        @window.left_composite.layout
      end
    end
  end
end

