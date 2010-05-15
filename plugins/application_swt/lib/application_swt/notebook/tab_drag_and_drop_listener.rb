module Redcar
  class ApplicationSWT
    class Notebook
      class TabDragAndDropListener
        include org.eclipse.swt.dnd.DragSourceListener
        include org.eclipse.swt.dnd.DropTargetListener
        
        # CTabItem state
        STATE_VARIABLES = [:control, :font, :tool_tip_text, :text, :image, :data]
        
        def initialize(tab_folder)
          @tab_folder = tab_folder
        end
        
        def dragStart(dsEvent)
          @dragging = true
          @source_item = @tab_folder.get_selection
        end
        
        def dragFinished(dsEvent)
          @dragging = false
        end
        
        def dropAccept(event)
          event.detail = Swt::DND::DND::DROP_NONE # Don't actually accept the drop
          if @dragging && @source_item
            target_tab_item = @tab_folder.get_item(@tab_folder.to_control(event.x, event.y))
            unless target_tab_item # drop happened behing the tabs
              target_tab_item = @tab_folder.get_items[@tab_folder.get_items.length - 1]
            end
            unless target_tab_item == @source_item # items need to be moved
              insert(@source_item, target_tab_item)
            end
          end
          @dragging = false
        end
        
        def insert(item1, item2)
          # Save the values of the item to be moved
          saved_values = STATE_VARIABLES.collect {|v| item1.send(v)}

          if @tab_folder.index_of(item1) < @tab_folder.index_of(item2)
            insert_after(item1, item2)
          else
            insert_before(item1, item2)
          end

          # finally, update the last item to make it the new position of the dropped item
          STATE_VARIABLES.each_with_index do |v, idx|
            item2.send(:"#{v}=", saved_values[idx])
          end
          @tab_folder.set_selection(item2)
        end
        
        def insert_after(item1, item2)
          # Exclude the last item from the list of moving items -> the moved on will go there
          moving_items = @tab_folder.get_items[@tab_folder.index_of(item1)...@tab_folder.index_of(item2)]
          move_in_place(moving_items, 1) # move all tabs down from right to left
        end
        
        def insert_before(item1, item2)
          # Exclude the first item from the list of moving items -> the moved on will go there
          moving_items = @tab_folder.get_items[(@tab_folder.index_of(item2) + 1)..@tab_folder.index_of(item1)]
          move_in_place(moving_items.to_a.reverse, -1) # move all tabs up from left to right
        end

        def move_in_place(array, offset)
          array.each do |item| # move all tabs up from left to right
            next_item = @tab_folder.get_item(@tab_folder.index_of(item) + offset)
            STATE_VARIABLES.each do |v|
              item.send(:"#{v}=", next_item.send(v))
            end
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