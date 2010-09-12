
module Redcar
  class EditView
    module Actions
      class DeleteHandler
        def self.handle(edit_view, modifiers)
          return if modifiers.any?
          delete_next(edit_view)
        end
        
        def self.delete_next(edit_view)
          return if edit_view.document.selection?
          return if edit_view.document.block_selection_mode?
          doc = edit_view.document
          old_offset = doc.cursor_offset
          new_offset = ArrowRightHandler.move_right_offset(edit_view)
          doc.delete(old_offset, new_offset - old_offset)
        end
      end
      
      class BackspaceHandler
        def self.handle(edit_view, modifiers)
          return if modifiers.any?
          delete_previous(edit_view)
        end
        
        def self.delete_previous(edit_view)
          return if edit_view.document.selection?
          return if edit_view.document.block_selection_mode?
          doc = edit_view.document
          old_offset = doc.cursor_offset
          new_offset = ArrowLeftHandler.move_left_offset(edit_view)
          doc.delete(new_offset, old_offset - new_offset)
        end
      end
    end
  end
end