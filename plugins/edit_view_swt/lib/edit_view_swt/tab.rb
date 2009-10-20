module Redcar
  class EditViewSWT
    class Tab
      attr_reader :item, :edit_view, :notebook
      
      def initialize(model, notebook)
        @model, @notebook = model, notebook
        @item = Swt::Custom::CTabItem.new(notebook.tab_folder, Swt::SWT::CLOSE)
        @item.text = "Hello!"
        
        @edit_view = EditViewSWT.new(self)
      end
      
    end
  end
end