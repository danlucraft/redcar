
module Redcar
  class AutoIndenter
    class DocumentController
      include Redcar::Document::Controller
      include Redcar::Document::Controller::NewlineCallback
      
      def after_newline(line_ix)
        if line_ix > 0
          previous_line     = document.get_line(line_ix - 1).gsub(document.delim, "")
          whitespace_prefix = whitespace_prefix(previous_line)
          offset            = document.offset_at_line(line_ix)
          document.insert(offset, whitespace_prefix)
          if document.cursor_offset == offset
            document.cursor_offset = offset + whitespace_prefix.length
          end
        end
      end
      
      private
      
      def whitespace_prefix(string)
        string[/^(\s*)(?:[^\s]|$)/, 1]
      end
    end
  end
end