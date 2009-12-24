
module Redcar
  class EditViewSWT
    class Document
      include Redcar::Observable
      attr_reader :swt_document
      
      def initialize(model, swt_document)
        @model = model
        @swt_document = swt_document
      end
      
      def to_s
        @swt_document.get
      end
      
      def length
        @swt_document.length
      end
      
      def line_count
        @swt_document.get_number_of_lines
      end
      
      def line_at_offset(offset)
        jface.get_line_of_offset(offset)
      end
      
      def offset_at_line(line_ix)
        jface.get_line_offset(line_ix)
      end
      
      def get_line(line_ix)
        line_info = jface.get_line_information(line_ix)
        jface.get(line_info.offset, line_info.length)
      end
      
      def insert(offset, text)
        jface.replace(offset, 0, text)
      end
      
      def cursor_offset
        @swt_document.styledText.get_caret_offset
      end
      
      def cursor_offset=(offset)
        @swt_document.styledText.set_caret_offset(offset)
      end
      
      def jface
        @swt_document.getJFaceDocument
      end
      
      def text=(text)
        @swt_document.set(text)
        notify_listeners(:set_text)
      end
    end
  end
end