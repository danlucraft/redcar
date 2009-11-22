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
      
      def initialize(model, shell)
        @model = model
        @model.controller = self
        create_tab_folder(shell)
        attach_model_listeners
        attach_view_listeners
        setup_drag_and_drop
      end
      
      def create_tab_folder(shell)
        folder_style = Swt::SWT::BORDER + Swt::SWT::CLOSE
        @tab_folder = Swt::Custom::CTabFolder.new(shell, folder_style)
    		@tab_folder.set_layout_data(Swt::Layout::GridData.new(Swt::Layout::GridData::FILL_BOTH))
    		@tab_folder.pack
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
