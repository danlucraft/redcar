module Redcar
  class EditView
    module Actions
  
      class ArrowHandler
        def self.real_offset_to_imaginary(line, width, offset)
          before = line[0...offset]
          before.length + (width - 1)*before.scan("\t").length
        end
  
        def self.imaginary_offset_to_real(line, width, offset)
          real_ix = 0
          imaginary_ix = 0
          prev_real_ix = 0
          prev_imaginary_ix = 0
          sc = StringScanner.new(line)
          while sc.skip(/[^\t]*\t/)
            prev_real_ix = real_ix
            prev_imaginary_ix = imaginary_ix
            imaginary_ix += sc.pos - real_ix + width - 1
            real_ix = sc.pos
            if imaginary_ix > offset
              return prev_real_ix + (offset - prev_imaginary_ix)
            elsif imaginary_ix == offset
              return real_ix
            end
          end
          real_ix + offset - imaginary_ix
        end
        
        def self.ensure_cursor_in_view(edit_view)
          edit_view.document.ensure_visible(edit_view.document.cursor_offset)
        end
      end
      
      class ArrowLeftHandler < ArrowHandler
        def self.handle(edit_view, modifiers)
          return if (modifiers & %w(Alt Cmd Ctrl)).any?
          if modifiers.include?("Shift")
            select_column_previous(edit_view)
          else
            column_previous(edit_view)
          end
        end
        
        def self.column_previous(edit_view)
          return false if edit_view.document.block_selection_mode?
          doc = edit_view.document
          if doc.selection?
            doc.cursor_offset = doc.selection_range.first
            doc.set_selection_range(doc.selection_range.first, doc.selection_range.first)
          else
            doc.cursor_offset = move_left_offset(edit_view)
          end
          ArrowHandler.ensure_cursor_in_view(edit_view)
          true
        end
        
        def self.select_column_previous(edit_view)
          return false if edit_view.document.block_selection_mode?
          doc = edit_view.document
          old_selection_offset = doc.selection_offset
          doc.set_selection_range(move_left_offset(edit_view), old_selection_offset)
          ArrowHandler.ensure_cursor_in_view(edit_view)
          true
        end
        
        def self.move_left_offset(edit_view)
          doc = edit_view.document
          return 0                                    if doc.cursor_offset == 0
          return doc.cursor_offset - doc.delim.length if doc.cursor_line_offset == 0
          if edit_view.soft_tabs?
            line = doc.get_line(doc.cursor_line)
            width = edit_view.tab_width
            imaginary_cursor_offset = real_offset_to_imaginary(line, width, doc.cursor_line_offset)
            if imaginary_cursor_offset % width == 0
              tab_stop = imaginary_cursor_offset/width - 1
            else
              tab_stop = imaginary_cursor_offset/width
            end
            tab_stop_offset = tab_stop*width
            next_tab_stop_offset = tab_stop_offset + width
            if line.length >= imaginary_offset_to_real(line, width, next_tab_stop_offset)
              before_line = line[imaginary_offset_to_real(line, width, tab_stop_offset)...doc.cursor_line_offset]
              if match = before_line.match(/\s+$/)
                doc.cursor_offset - match[0].length
              else
                doc.cursor_offset - 1
              end
            else
              doc.cursor_offset - 1
            end
          else
            doc.cursor_offset - 1
          end
        end
      end
      
      class ArrowRightHandler < ArrowHandler
        def self.handle(edit_view, modifiers)
          return if (modifiers & %w(Alt Cmd Ctrl)).any?
          if modifiers.include?("Shift")
            select_column_next(edit_view)
          else
            column_next(edit_view)
          end
        end
        
        def self.column_next(edit_view)
          return false if edit_view.document.block_selection_mode?
          doc = edit_view.document
          if doc.selection?
            doc.cursor_offset = doc.selection_range.last
            doc.set_selection_range(doc.selection_range.last, doc.selection_range.last)
          else
            doc.cursor_offset = move_right_offset(edit_view)
          end
          ArrowHandler.ensure_cursor_in_view(edit_view)
          true
        end
        
        def self.select_column_next(edit_view)
          return false if edit_view.document.block_selection_mode?
          doc = edit_view.document
          old_selection_offset = doc.selection_offset
          doc.set_selection_range(move_right_offset(edit_view), old_selection_offset)
          ArrowHandler.ensure_cursor_in_view(edit_view)
          true
        end
        
        def self.move_right_offset(edit_view)
          doc = edit_view.document
          [move_right_offset1(edit_view), doc.length].min
        end
        
        def self.move_right_offset1(edit_view)
          doc = edit_view.document
          return doc.length if doc.cursor_offset == doc.length - 1
          if doc.length >= doc.cursor_offset + doc.delim.length and 
              doc.get_range(doc.cursor_offset, doc.delim.length) == doc.delim
            return doc.cursor_offset + doc.delim.length
          end
          if edit_view.soft_tabs?
            line = doc.get_line(doc.cursor_line)
            width = edit_view.tab_width
            imaginary_cursor_offset = real_offset_to_imaginary(line, width, doc.cursor_line_offset)
            tab_stop = imaginary_cursor_offset/width + 1
            tab_stop_offset = tab_stop*width
            if line.length >= imaginary_offset_to_real(line, width, tab_stop_offset)
              after_line = line[doc.cursor_line_offset...imaginary_offset_to_real(line, width, tab_stop_offset)]
              if match = after_line.match(/^\s+/)
                doc.cursor_offset + match[0].length
              else
                incremented_offset(doc)
              end
            else
              incremented_offset(doc)
            end
          else
            incremented_offset(doc)
          end
        end
        
        def self.incremented_offset(doc)
          doc.cursor_offset + 1
        end
      end
    end
  end
end