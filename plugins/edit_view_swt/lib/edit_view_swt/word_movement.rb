
module Redcar
  class EditViewSWT
    class WordMoveListener
      MOVE_FORWARD_RE = /\s{3,}|[^\w]{2,}|(\s|[^\w])?\w+/
    
      def initialize(controller)
        @controller = controller
      end
      
      def get_next_offset(e)
        if [Swt::SWT::MOVEMENT_WORD, Swt::SWT::MOVEMENT_WORD_END].include? e.movement
          e.newOffset = next_offset(e.offset, e.lineOffset, e.lineText)
          # SWT gets pissy without this:
          if e.newOffset == e.lineOffset + e.lineText.chars.length + 1
            e.newOffset += 1
          end
        end
      end
      
      def next_offset(chars_offset, chars_line_offset, line_text)
        if chars_offset == chars_line_offset + line_text.chars.length
          chars_offset + 1
        else
          future_text = line_text.chars[(chars_offset - chars_line_offset)..-1].to_s
          if future_text == nil or future_text == ""
            chars_line_offset + line_text.chars.length
          else
            if md = future_text.match(MOVE_FORWARD_RE)
              chars_match_end = future_text.byte_offset_to_char_offset(md.end(0))
              chars_offset + chars_match_end
            else
              chars_line_offset + line_text.chars.length
            end
          end
        end
      end
      
      def get_previous_offset(e)
        if [Swt::SWT::MOVEMENT_WORD, Swt::SWT::MOVEMENT_WORD_START].include? e.movement
          e.newOffset = previous_offset(e.offset, e.lineOffset, e.lineText)
          # SWT gets pissy without this:
          if e.newOffset == e.lineOffset - 1
            e.newOffset -= 1
          end
        end
      end
      
      def previous_offset(chars_offset, chars_line_offset, line_text)
        if chars_offset == chars_line_offset
          chars_offset - 1
        else
          future_text = line_text.chars[0..(chars_offset - chars_line_offset - 1)].reverse.to_s
          if future_text == nil or future_text == ""
            chars_line_offset
          else
            if md = future_text.match(MOVE_FORWARD_RE)
              chars_match_end = future_text.byte_offset_to_char_offset(md.end(0))
              chars_offset - chars_match_end
            else
              chars_line_offset
            end
          end
        end
      end
    end
  end
end