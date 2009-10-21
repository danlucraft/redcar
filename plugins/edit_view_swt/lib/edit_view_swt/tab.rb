module Redcar
  class EditViewSWT
    class Tab < ApplicationSWT::Tab
      attr_reader :item, :edit_view, :notebook
      
      def initialize(model, notebook)
        super
      end
      
      def create_item_widget
        @item = Swt::Custom::CTabItem.new(notebook.tab_folder, Swt::SWT::CLOSE)
        @item.text = "Hello!"
        
        @edit_view = EditViewSWT.new(self)
      end
      
      # Focuses the CTabItem within the CTabFolder, and gives the keyboard
      # focus to the EditViewSWT.
      def focus
        super
        @edit_view.focus
      end
    end
  end
end