module Redcar
  class EditView
    module Actions
      class IndentTabHandler
        def self.priority
          1
        end
        
        def self.handle(edit_view, modifiers)
          return false if modifiers.any?
          doc = edit_view.document
          if doc.block_selection_mode?
            if edit_view.soft_tabs?
              selections = doc.selection_ranges.map do |selection_range|
                line = doc.line_at_offset(selection_range.begin)
                line_offset = doc.offset_at_line(line)
                line_offset_start = selection_range.begin - line_offset
                line_offset_end = selection_range.end - line_offset
                [line, line_offset_start, line_offset_end]
              end
              length = 0
              selections.each do |line, line_offset_start, line_offset_end|
                line_offset = doc.offset_at_line(line)
                doc.replace(line_offset + line_offset_start, line_offset_end - line_offset_start, " "*(line_offset_end - line_offset_start))
                length = line_offset_end - line_offset_start
              end
              line = doc.get_line(doc.cursor_line)
              width = edit_view.tab_width
              imaginary_cursor_offset = ArrowHandler.real_offset_to_imaginary(line, width, doc.cursor_line_offset)
              next_tab_stop_offset = (imaginary_cursor_offset/width + 1)*width
              insert_string = " "*(next_tab_stop_offset - imaginary_cursor_offset)
              selections.each do |line, line_offset_start, line_offset_end|
                line_offset = doc.offset_at_line(line)
                doc.insert(line_offset + line_offset_start, insert_string)
              end
              new_selection_ranges = selections.map do |line, line_offset_start, line_offset_end|
                offset = doc.offset_at_line(line) + line_offset_end + insert_string.length
                [offset, offset]
              end
              doc.set_selection_range(new_selection_ranges.last.last, new_selection_ranges.first.first)
              true
            else
              false
            end
          else
            if doc.selection?
              bits = [doc.cursor_offset, doc.selection_offset].sort
              start = bits.first
              length = bits.last - bits.first
              doc.delete(start, length)
            end
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
end