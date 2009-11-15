module Redcar
  class ApplicationSWT
    class Tab
      attr_reader :item, :model
      
      def initialize(model, notebook)
        @model, @notebook = model, notebook
        create_item_widget
        attach_listeners
      end
      
      def create_item_widget
        @item = Swt::Custom::CTabItem.new(notebook.tab_folder, Swt::SWT::CLOSE)
        @item.text = "Hello!"
        text = Swt::Widgets::Text.new(notebook.tab_folder, Swt::SWT::MULTI)
        text.text = "Example of a tab"
        @item.control = text
      end
      
      def attach_listeners
        @model.add_listener(:focus, &method(:focus))
        @model.add_listener(:close, &method(:close))
      end
      
      def focus
        @notebook.model_event_focus_tab(self)
      end
      
      def close
        @item.dispose
      end
    end
  end
end