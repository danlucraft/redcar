module Redcar
  class ApplicationSWT
    class Notebook
      include Redcar::Observable
      
      attr_reader :tab_folder, :model
      
      class CTabFolder2Listener
        def initialize(controller)
          @controller = controller
        end
        
        def close(event)
          if event.item
            tab = @controller.tab_widget_to_tab_model(event.item)
            unless Redcar.app.events.ignore?(:tab_close, tab)
              event.doit = false
              Redcar.app.events.create(:tab_close, tab)
            end
          end
        end
        
        def show_list(event); end
        def maximize(*_); end
        def minimize(*_); end
        def restore(*_); end
      end
      
      class SelectionListener
        def initialize(controller)
          @controller = controller
        end
        
        def widgetSelected(event)
          if event.item
            tab = @controller.tab_widget_to_tab_model(event.item)
            unless Redcar.app.events.ignore?(:tab_focus, tab)
              event.doit = false
              Redcar.app.events.create(:tab_focus, tab)
            end
          end
        end
        
        def widgetDefaultSelected(*_)
        end
      end
      
      def initialize(model, sash)
        @model = model
        @model.controller = self
        create_tab_folder(sash)
        style_tab_folder
        attach_model_listeners
        attach_view_listeners
      end

      def create_tab_folder(sash)
        folder_style = Swt::SWT::CLOSE
        @tab_folder = Swt::Custom::CTabFolder.new(sash, folder_style)
        font_data = @tab_folder.font.font_data.first
        font = Swt::Graphics::Font.new(
          ApplicationSWT.display,
          font_data.name,
          Redcar::EditView.font_size - 1,
          Swt::SWT::NORMAL)
        @tab_folder.font = font
        grid_data = Swt::Layout::GridData.new
        grid_data.grabExcessHorizontalSpace = true
        grid_data.horizontalAlignment = Swt::Layout::GridData::FILL
        @tab_folder.set_layout_data(grid_data)
        @tab_folder.pack
        register_tab_dnd(@tab_folder)
      end
      
      def register_tab_dnd(tab_folder)
        dnd_listener = TabDragAndDropListener.new(self)
        operations = (Swt::DND::DND::DROP_COPY | Swt::DND::DND::DROP_DEFAULT | Swt::DND::DND::DROP_MOVE)
        transfer_types = [TabTransfer.get_instance].to_java(:"org.eclipse.swt.dnd.ByteArrayTransfer")
        
        drag_source = Swt::DND::DragSource.new(tab_folder, operations)
        drag_source.set_transfer(transfer_types)
        drag_source.add_drag_listener(dnd_listener)
        
        drop_target = Swt::DND::DropTarget.new(tab_folder, operations)
        drop_target.set_transfer(transfer_types)
        drop_target.add_drop_listener(dnd_listener)
      end
      
      def style_tab_folder
        selected_tab_background = Redcar::ApplicationSWT.selected_tab_background
        @tab_folder.set_selection_background(selected_tab_background.swt_colors, selected_tab_background.swt_stops, true)

        unselected_tab_background = Redcar::ApplicationSWT.unselected_tab_background
        @tab_folder.set_background(unselected_tab_background.swt_colors, unselected_tab_background.swt_stops, true)
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
      
      # Called by the models when a tab is selected by Redcar.
      def model_event_focus_tab(tab)
        tab_folder.set_selection(tab.item)
        @model.select_tab!(tab.model)
      end

      def model_event_tab_moved(from_notebook, to_notebook, tab_model)
        tab_controller = tab_model.controller
        title          = tab_model.title
        tab_controller.set_notebook(to_notebook.controller)
        tab_controller.create_item_widget
        tab_controller.move_tab_widget_to_current_notebook
        tab_controller.focus
        tab_model.title = title
      end
      
      def recalculate_tab_order
        @model.sort_tabs! do |a,b|
          tab_folder.index_of(a.controller.item) <=> tab_folder.index_of(b.controller.item)
        end
      end
      
      def dispose
        @tab_folder.dispose
      end
      
      def tab_widget_to_tab_model(tab_widget)
        @model.tabs.detect {|tab| tab.controller.item == tab_widget }
      end

      private
      
      def focussed_tab
        focussed_tab_item = tab_folder.get_selection
        @model.tabs.detect {|tab| tab.controller.item == focussed_tab_item }
      end
      
    end
  end
end
