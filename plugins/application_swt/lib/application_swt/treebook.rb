require 'swt/vtab_folder'
require 'swt/vtab_item'

module Redcar
  class ApplicationSWT
    class Treebook
      attr_reader :tab_folder, :font

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
        i = Swt::Widgets::VTabItem.new(@tab_folder, Swt::SWT::NULL)
        i.text = tree.tree_mirror.title
        i.control = TreeViewSWT.new(@tab_folder, tree)
        tree.controller = i.control
        @tab_folder.selection = i
      end

      def tree_removed(tree)
        tree.controller.close
        @tab_folder.remove_item(@tab_folder.get_item(tree.tree_mirror.title))
      end

      def tree_focussed(tree)
        item = @tab_folder.get_item(tree.tree_mirror.title)
        @tab_folder.selection = item
      end

      def create_tree_view
        @tab_folder = Swt::Widgets::VTabFolder.new(@window.tree_sash, Swt::SWT::NONE)
        font_data = @tab_folder.font.font_data.first
        font = Swt::Graphics::Font.new(
          ApplicationSWT.display,
          font_data.name,
          Redcar::EditView.font_size - 1,
          Swt::SWT::NORMAL)
        @tab_folder.font = font
        selected_tab_background = Redcar::ApplicationSWT.selected_tab_background
        @tab_folder.set_selection_background(selected_tab_background.swt_colors, selected_tab_background.swt_stops, true)

        unselected_tab_background = Redcar::ApplicationSWT.unselected_tab_background
        @tab_folder.set_background(unselected_tab_background.swt_colors, unselected_tab_background.swt_stops, true)

        attach_view_listeners

        @tab_folder.layout
        @window.left_composite.layout
      end

      def attach_view_listeners
        @tab_folder.add_ctab_folder2_listener do |event|
          # Close event
          tab_item = event.item
          tree_view_swt = tab_item.control
          @model.remove_tree(tree_view_swt.model)
        end

        @tab_folder.add_selection_listener do |event|
          # Widget selected event
          tab_item = event.item
          tree_view_swt = tab_item.control
          tree = tree_view_swt.model
          @model.focus_tree(tree)
        end
      end
    end
  end
end
