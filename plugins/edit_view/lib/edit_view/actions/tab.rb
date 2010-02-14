module Redcar
  class EditView
    module Actions
      class IndentTabHandler
        def self.handle(edit_view, modifiers)
          return false if modifiers.any?
          doc = edit_view.document
          if edit_view.soft_tabs?
            line = doc.get_line(doc.cursor_line)
            width = edit_view.tab_width
            imaginary_cursor_offset = ArrowHandler.real_offset_to_imaginary(line, width, doc.cursor_line_offset)
            next_tab_stop_offset = (imaginary_cursor_offset/width + 1)*width
            insert_string = " "*(next_tab_stop_offset - imaginary_cursor_offset)
            doc.insert(doc.cursor_offset, insert_string)
            doc.cursor_offset = doc.cursor_offset + insert_string.length
          else
            doc.insert(doc.cursor_offset, "\t")
            doc.cursor_offset += 1
          end
          true
        end
      end
    end
  end
end