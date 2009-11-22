module Redcar
  class ApplicationSWT
    class Notebook
      class DragAndDropListener
  
        def initialize(tab_folder)
          @tab_folder       = tab_folder
          @drag, @exit_drag = false, false
          @drag_item        = nil
        end
  
        def handleEvent(e)
          if e.type == Swt::SWT::DragDetect
            p = @tab_folder.toControl(Swt::Widgets::Display.getCurrent.getCursorLocation) # see bug 43251
          else
            p = Swt::Graphics::Point.new(e.x, e.y)
          end
          case e.type
          when Swt::SWT::DragDetect
            item = @tab_folder.getItem(p)
            return unless item
            @drag = true
            @exit_Drag = false
            @drag_item = item
          when Swt::SWT::MouseEnter
            if @exit_drag
              @exit_drag = false;
              @drag = (e.button != 0)
            end
          when Swt::SWT::MouseExit
            if @drag
              @tab_folder.setInsertMark(nil, false)
              @exit_drag = true
              @drag = false
            end
          when Swt::SWT::MouseUp
            return unless @drag
            @tab_folder.setInsertMark(nil, false)
            if item = @tab_folder.getItem(Swt::Graphics::Point.new(p.x, 1))
              rect = item.getBounds()
              after = (p.x > rect.x + rect.width/2)
              index = @tab_folder.indexOf(item)
              index = after ? index + 1 : index -1
              index = [0, index].max
              new_item = Swt::Custom::CTabItem.new(@tab_folder, Swt::SWT::NONE, index)
              new_item.setText("new tab item")
              c = @drag_item.getControl()
              @drag_item.setControl(nil)
              new_item.setControl(c)
              @drag_item.dispose()
              @tab_folder.setSelection(new_item)
            end
            @drag = false
            @exit_drag = false
            @drag_item = nil
          when Swt::SWT::MouseMove
            return unless @drag
            item = @tab_folder.getItem(Swt::Graphics::Point.new(p.x, 2))
            unless item 
              @tab_folder.setInsertMark(nil, false)
              return
            end
            rect = item.getBounds
            after = (p.x > rect.x + rect.width/2)
            @tab_folder.setInsertMark(item, after)
          end
        end
      end
    end
  end
end