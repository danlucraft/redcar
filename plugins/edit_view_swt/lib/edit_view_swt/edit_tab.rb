module Redcar
  class EditViewSWT
    class Tab < ApplicationSWT::Tab
      include Redcar::Observable
      
      attr_reader :item, :edit_view
      
      def initialize(*args)
        super
        @model.add_listener(:changed_title) { |title| @item.text = title }
      end
      
      # Focuses the CTabItem within the CTabFolder, and gives the keyboard
      # focus to the EditViewSWT.
      def focus
        super
        edit_view.focus
      end
      
      # Close the EditTab, disposing of any resources along the way.
      def close
        @edit_view.dispose
        @widget.dispose
        super
      end
      
      private
      
      def create_tab_widget
        @widget = Swt::Widgets::Composite.new(notebook.tab_folder, Swt::SWT::NONE)
        layout = Swt::Layout::GridLayout.new(1, false)
        layout.verticalSpacing = 0
        layout.marginHeight = 0
        layout.horizontalSpacing = 0
        layout.marginWidth = 0
        @widget.layout = layout
        @edit_view = EditViewSWT.new(model.edit_view, @widget)
        
        grid_data = Swt::Layout::GridData.new(
                      Swt::Layout::GridData::FILL_BOTH | 
                      Swt::Layout::GridData::VERTICAL_ALIGN_FILL |
                      Swt::Layout::GridData::HORIZONTAL_ALIGN_FILL)
        @edit_view.mate_text.get_control.parent.set_layout_data(grid_data)

        @item.control = @widget
        @widget.pack
      end
    end
  end
end
