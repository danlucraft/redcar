module Redcar
  class ApplicationSWT
    class Tab
      attr_reader :item, :model
      
      FILE_ICON = File.join(Redcar.root, %w(plugins application lib application assets file.png))
      
      def initialize(model, notebook)
        @model, @notebook = model, notebook
        create_item_widget
        create_tab_widget
        attach_listeners
        @icon = Swt::Graphics::Image.new(ApplicationSWT.display, FILE_ICON)
        @item.image = @icon
      end
      
      def create_item_widget
        @item = Swt::Custom::CTabItem.new(notebook.tab_folder, Swt::SWT::CLOSE)
        @item.text = "Hello!"
      end
      
      def create_tab_widget
        text = Swt::Widgets::Text.new(notebook.tab_folder, Swt::SWT::MULTI)
        text.text = "Example of a tab"
        @item.control = text
      end
      
      def set_notebook(notebook_controller)
        @notebook = notebook_controller
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
        @icon.dispose
      end
    end
  end
end