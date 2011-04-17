module Redcar
  class ApplicationSWT
    class Tab
      
      attr_reader :item, :model, :notebook, :widget
      
      def initialize(model, notebook, position = nil)
        @model, @notebook = model, notebook
        create_item_widget(position || @notebook.tab_folder.item_count)
        create_tab_widget
        attach_listeners
      end
      
      def create_item_widget(position = nil)
        position ||= notebook.tab_folder.item_count
        if @item
          @item.dispose
        end
        @item = Swt::Custom::CTabItem.new(notebook.tab_folder, Swt::SWT::CLOSE, position)
        set_icon(@model.icon)
      end
      
      def set_icon(icon)
        @item.image = @icon = ApplicationSWT::Icon.swt_image(icon)
      end
      
      def create_tab_widget
        @widget = Swt::Widgets::Text.new(notebook.tab_folder, Swt::SWT::MULTI)
        @widget.text = "Example of a tab"
        @item.control = @widget
      end
      
      def dragging?
        @dragging
      end
      
      def dragging= boolean
        @dragging = boolean
      end
      
      def move_tab_widget_to_current_notebook
        @widget.setParent(notebook.tab_folder)
        @item.control = @widget
      end

      def move_tab_widget_to_position(position)
        # CTabItem state
        state_variables = [:font, :tool_tip_text, :text]
        view_state = state_variables.collect {|var| @item.send(var)}
        create_item_widget(position)
        state_variables.each_with_index {|var, idx| @item.send(:"#{var}=", view_state[idx])}
        @item.control = @widget
        @item.image = @icon
        @notebook.recalculate_tab_order
        focus
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
        @model.add_listener(:moved, &method(:move_tab_widget_to_position))
        @model.add_listener(:changed_icon, &method(:set_icon))
      end
      
      def focus
        @notebook.model_event_focus_tab(self)
      end
      
      def close
        @item.dispose if @item
        @widget.dispose if @widget
      end
    end
  end
end

