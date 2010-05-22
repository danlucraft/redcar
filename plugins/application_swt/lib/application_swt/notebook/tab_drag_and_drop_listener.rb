module Redcar
  class ApplicationSWT
    class Notebook
      class TabDragAndDropListener
        include org.eclipse.swt.dnd.DragSourceListener
        include org.eclipse.swt.dnd.DropTargetListener
        
        class TabPaintListener
          include org.eclipse.swt.events.PaintListener    
          attr_writer :item
      
          def paintControl(event)
            if @item
              bounds = @item.bounds
              side_length = bounds.height / 3
              triangle = [bounds.x + 2, bounds.y + side_length,
                bounds.x + side_length + 2, bounds.y,
                bounds.x - side_length + 2, bounds.y]
              event.gc.background = ApplicationSWT.display.system_color Swt::SWT::COLOR_DARK_GRAY
              event.gc.fill_polygon(triangle.to_java(:int))
            end
          end
        end
        
        def initialize(notebook)
          @notebook = notebook
          @paint_listener = TabPaintListener.new
        end
        
        def tab_folder
          @notebook.tab_folder
        end
        
        def dragStart(event)
          @dragging = true
          @source_item = tab_folder.selection
          tab_folder.add_paint_listener(@paint_listener)
        end
        
        def dragFinished(event)
          @dragging = @source_item = nil
          tab_folder.remove_paint_listener(@paint_listener)
          tab_folder.redraw
        end
        
        def dropAccept(event)
          event.detail = Swt::DND::DND::DROP_NONE # Don't actually accept the drop as native DnD
          if @dragging && @source_item
            target_tab_item = event_to_tab_item(event)
            unless target_tab_item == @source_item # items need to be moved
              move_behind(@source_item, target_tab_item)
            end
          end
          dragFinished(event)
        end
        
        def move_behind(item1, item2)
          tab_controller = @notebook.tab_widget_to_tab_model(item1).controller
          if tab_controller
            tab_controller.move_to_position(tab_folder.index_of(item2))
          end
        end
        
        def dragOver(event)
          @paint_listener.item = event_to_tab_item(event)
          tab_folder.redraw
        end
        
        def event_to_tab_item(event)
          tab_folder.item(tab_folder.to_control(event.x, event.y)) or 
          tab_folder.items[tab_folder.item_count - 1]
        end

        # Must implement the java interface
        def dragSetData(dsEvent); end
        def dragEnter(event); end
        def dragLeave(event); end
        def dragOperationChanged(event); end
        def drop(event); end
      end
    end
  end
end

