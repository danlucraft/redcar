module Redcar
  class ApplicationSWT
    class Notebook
      class TabDragAndDropListener
        include org.eclipse.swt.dnd.DragSourceListener
        include org.eclipse.swt.dnd.DropTargetListener
        
        def initialize(notebook)
          @notebook = notebook
        end
        
        def tab_folder
          @notebook.tab_folder
        end
        
        def dragStart(event)
          @dragging = true
          @source_item = tab_folder.selection
        end
        
        def dragFinished(event)
          @dragging = @source_item = nil
        end
        
        def dropAccept(event)
          event.detail = Swt::DND::DND::DROP_NONE # Don't actually accept the drop as native DnD
          if @dragging && @source_item
            target_tab_item = tab_folder.item(tab_folder.to_control(event.x, event.y))
            unless target_tab_item # drop happened behing the tabs
              target_tab_item = tab_folder.items[tab_folder.item_count - 1]
            end
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

        # Must implement the java interface
        def dragSetData(dsEvent); end
        def dragEnter(event); end
        def dragLeave(event); end
        def dragOperationChanged(event); end
        def dragOver(event); end
        def drop(event); end
      end
    end
  end
end

