module Redcar
  class ApplicationSWT
    class Notebook
      attr_reader :tab_folder
      
      class CTabFolder2Listener
        def initialize(controller)
          @controller = controller
        end
        
        def close(event)
          @controller.swt_event_tab_closed(event.item)
        end
      end
      
      class SelectionListener
        def initialize(controller)
          @controller = controller
        end
        
        def widgetSelected(event)
          @controller.swt_event_tab_selected(event.item)
        end
      end
      
      def initialize(model, sash)
        @model = model
        @model.controller = self
        create_tab_folder(sash)
        style_tab_folder
        attach_model_listeners
        attach_view_listeners
        setup_drag_and_drop
      end
      
      def create_tab_folder(sash)
        folder_style = Swt::SWT::BORDER + Swt::SWT::CLOSE
        @tab_folder = Swt::Custom::CTabFolder.new(sash, folder_style)
        grid_data = Swt::Layout::GridData.new(Swt::Layout::GridData::FILL_BOTH)
        @tab_folder.set_layout_data(grid_data)
        @tab_folder.pack
      end
      
      def style_tab_folder
        colors = [
          Swt::Graphics::Color.new(ApplicationSWT.display, 230, 240, 255),
          Swt::Graphics::Color.new(ApplicationSWT.display, 170, 199, 246),
          Swt::Graphics::Color.new(ApplicationSWT.display, 135, 178, 247)
        ].to_java(Swt::Graphics::Color)
        percents = [40, 85].to_java(:int)
        
        @tab_folder.setSelectionBackground(colors, percents, true)
      end
      
      def setup_drag_and_drop
        listener = DragAndDropListener.new(@tab_folder)
        @tab_folder.addListener(Swt::SWT::DragDetect, listener)
        @tab_folder.addListener(Swt::SWT::MouseUp, listener)
        @tab_folder.addListener(Swt::SWT::MouseMove, listener)
        @tab_folder.addListener(Swt::SWT::MouseExit, listener)
        @tab_folder.addListener(Swt::SWT::MouseEnter, listener)
      end
      
      def attach_model_listeners
        @model.add_listener(:tab_added) do |tab|
          tab.controller = Redcar.gui.controller_for(tab).new(tab, self)
        end
        @model.add_listener(:tab_moved, &method(:model_event_tab_moved))
      end
      
      def attach_view_listeners
        @tab_folder.add_ctab_folder2_listener(CTabFolder2Listener.new(self))
        @tab_folder.add_selection_listener(SelectionListener.new(self))
      end
      
      # Called by the SWT event listener when a tab is closed by the user.
      def swt_event_tab_closed(tab_widget)
        @model.remove_tab!(tab_widget_to_tab_model(tab_widget))
      end
      
      # Called by the SWT event listener when a tab is selected by the user.
      def swt_event_tab_selected(tab_widget)
        @model.select_tab!(tab_widget_to_tab_model(tab_widget))
      end
      
      # Called by the models when a tab is selected by Redcar.
      def model_event_focus_tab(tab)
        tab_folder.set_selection(tab.item)
        @model.select_tab!(tab.model)
      end
      
      def model_event_tab_moved(from_notebook_model, to_notebook_model, tab_model)
        tab_controller = tab_model.controller
        data = tab_model.serialize
        tab_controller.close
        tab_controller.set_notebook(to_notebook_model.controller)
        tab_controller.create_item_widget
        tab_controller.create_tab_widget
        tab_controller.focus
        tab_model.deserialize(data)
      end
      
      private
      
      def focussed_tab
        focussed_tab_item = tab_folder.get_selection
        @model.tabs.detect {|tab| tab.controller.item == focussed_tab_item }
      end
      
      def tab_widget_to_tab_model(tab_widget)
        @model.tabs.detect {|tab| tab.controller.item == tab_widget }
      end
    end
  end
end
