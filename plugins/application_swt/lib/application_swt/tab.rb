module Redcar
  class ApplicationSWT
    class Tab
      attr_reader :item, :model, :notebook, :widget
      
      FILE_ICON = File.join(Redcar.root, %w(plugins application lib application assets file.png))
      
      def initialize(model, notebook)
        @model, @notebook = model, notebook
        create_item_widget
        create_tab_widget
        attach_listeners
      end
      
      def create_item_widget
        if @item
          @item.dispose
        end
        @item = Swt::Custom::CTabItem.new(notebook.tab_folder, Swt::SWT::CLOSE)
        @icon = Swt::Graphics::Image.new(ApplicationSWT.display, FILE_ICON)
        @item.image = @icon
      end
      
      def create_tab_widget
        @widget = Swt::Widgets::Text.new(notebook.tab_folder, Swt::SWT::MULTI)
        @widget.text = "Example of a tab"
        @item.control = @widget
      end
      
      def move_tab_widget_to_current_notebook
        @widget.setParent(notebook.tab_folder)
        @item.control = @widget
      end
      
      def set_notebook(notebook_controller)
        @notebook = notebook_controller
      end
      
      def swt_focus_gained
        notify_listeners(:swt_focus_gained)
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

