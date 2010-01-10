
module Redcar
  class EditViewSWT
    class Document
      include Redcar::Observable
      attr_reader :jface_document
      
      def initialize(model, swt_mate_document)
        @model          = model
        @swt_mate_document = swt_mate_document
        @jface_document = swt_mate_document.mateText.get_document
      end
      
      def attach_modification_listeners
        jface_document.add_document_listener(DocumentListener.new(@model))
        styledText.add_selection_listener(SelectionListener.new(@model))
      end
      
      def to_s
        jface_document.get
      end
      
      def length
        jface_document.length
      end
      
      def line_count
        jface_document.get_number_of_lines
      end
      
      def line_at_offset(offset)
        jface_document.get_line_of_offset(offset)
      end
      
      def offset_at_line(line_ix)
        jface_document.get_line_offset(line_ix)
      end
      
      def get_line(line_ix)
        line_info = jface_document.get_line_information(line_ix)
        jface_document.get(line_info.offset, line_info.length)
      end
      
      def get_range(start, length)
        jface_document.get(start, length)
      end
      
      def replace(offset, length, text)
        @model.verify_text(offset, offset+length, text)
        jface_document.replace(offset, length, text)
        if length > text.length
          @swt_mate_document.mateText.redraw
        end
        @model.modify_text
      end
      
      def text=(text)
        @model.verify_text(0, length, text)
        jface_document.set(text)
        @model.modify_text
        notify_listeners(:set_text)
      end
      
      def cursor_offset
        styledText.get_caret_offset
      end
      
      def cursor_offset=(offset)
        styledText.set_caret_offset(offset)
      end
      
      def selection_range
        range = styledText.get_selection_range
        range.x...(range.x + range.y)
      end
      
      def set_selection_range(start, _end)
        styledText.set_selection(start, _end)
        @model.selection_range_changed(start, _end)
      end
      
      def styledText
        @swt_mate_document.mateText.getControl
      end
      
      class SelectionListener
        def initialize(model)
          @model = model
        end

        def widget_default_selected(e)
          @model.selection_range_changed(e.x, e.y)
        end
        
        def widget_selected(e)
          @model.selection_range_changed(e.x, e.y)
        end        
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
    end
  end
end
