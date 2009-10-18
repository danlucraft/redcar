module Redcar
  class EditViewSWT
    class Tab
      attr_reader :item, :mate_text
      
      def initialize(model, notebook)
        @model, @notebook = model, notebook
        @item = Swt::Custom::CTabItem.new(notebook.tab_folder, Swt::SWT::CLOSE)
        @item.text = "Hello!"
        
        @contents = Swt::Widgets::Composite.new(notebook.tab_folder, Swt::SWT::NONE)
        @contents.layout = Swt::Layout::FillLayout.new
        @mate_text = JavaMateView::MateText.new(@contents)
        @mate_text.set_grammar_by_name "Ruby"
        @mate_text.set_theme_by_name "Twilight"
        @mate_text.set_font "Monaco", 15
        @item.control = @contents
      end
      
      def document
        EditViewSWT::Document.new(self.mate_text.document)
      end
    end
  end
end