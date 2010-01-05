
module Redcar
  class EditViewSWT
    class Document
      include Redcar::Observable
      attr_reader :swt_document
      
      def initialize(model, swt_document)
        @model        = model
        @swt_document = swt_document
      end
      
      def attach_modification_listeners
        jface.add_document_listener(DocumentListener.new(@model))
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
      
      def replace(offset, length, text)
        jface.replace(offset, length, text)
      end
      
      def cursor_offset
        @swt_document.styledText.get_caret_offset
      end
      
      def cursor_offset=(offset)
        @swt_document.styledText.set_caret_offset(offset)
      end
      
      # Returns the offset range selected in the document. The start of the range is always
      # before the end of the range, even if the selection is right-to-left
      #
      # @return [Range<Integer>] offset range
      def selection_range
        range = @swt_document.styledText.get_selection_range
        range.x...(range.x + range.y)
      end
      
      def set_selection_range(start, _end)
        @swt_document.styledText.set_selection(start, _end)
      end
      
      def jface
        @swt_document.getJFaceDocument
      end
      
      class DocumentListener
        def initialize(model)
          @model = model
        end
        
        def document_about_to_be_changed(e)
          @model.about_to_be_changed(e.offset, e.length, e.text)
        end
        
        def document_changed(e)
          @model.changed(e.offset, e.length, e.text)
        end
      end
      
      def text=(text)
        jface.set(text)
        notify_listeners(:set_text)
      end
    end
  end
end
