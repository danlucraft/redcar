module Redcar
  class ApplicationSWT
    class Tab
      attr_reader :item
      
      def initialize(model, notebook)
        @model, @notebook = model, notebook
        @item = Swt::Custom::CTabItem.new(notebook.tab_folder, Swt::SWT::CLOSE)
        @item.text = "Hello!"
        text = Swt::Widgets::Text.new(notebook.tab_folder, Swt::SWT::MULTI)
        text.text = "Example of a tab"
        @item.control = text
      end
    end
  end
end