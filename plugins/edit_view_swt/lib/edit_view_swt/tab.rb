module Redcar
  class EditViewSWT
    class Tab
      attr_reader :item, :edit_view
      
      def initialize(model, notebook)
        @model, @notebook = model, notebook
        @item = Swt::Custom::CTabItem.new(notebook.tab_folder, Swt::SWT::CLOSE)
        @item.text = "Hello!"
        
        @edit_view = EditViewSWT.new(notebook.tab_folder)
        @item.control = @edit_view.widget
      end
      
    end
  end
end