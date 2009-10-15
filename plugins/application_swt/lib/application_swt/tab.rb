module Redcar
  class ApplicationSWT
    class Tab
      def initialize(model, notebook)
        @model, @notebook = model, notebook
        tab_item = Swt::Custom::CTabItem.new(notebook.tab_folder, Swt::SWT::CLOSE)
        tab_item.text = "Hello!"
        text = Swt::Widgets::Text.new(notebook.tab_folder, Swt::SWT::MULTI)
        text.text = "Big Text"
        tab_item.control = text
      end
    end
  end
end