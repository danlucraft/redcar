
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

      def right_click(edit_view)
        menu = Menu.new
        Redcar.plugin_manager.objects_implementing(:edit_view_context_menus).each do |object|
          case object.method(:edit_view_context_menus).arity
          when 0
            menu.merge(object.edit_view_context_menus)
          when 1
            menu.merge(object.edit_view_context_menus(edit_view))
          else
            puts("Invalid edit_view_context_menus hook detected in "+object.class.name)
          end
        end
        Application::Dialog.popup_menu(menu, :pointer)
      end
      
      def attach_modification_listeners
        jface_document.add_document_listener(DocumentListener.new(@model))
        styledText.add_selection_listener(SelectionListener.new(@model))
        styledText.add_caret_listener(CaretListener.new(@model))
      end

      def single_line?
        @swt_mate_document.mateText.isSingleLine
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

      def get_line_delimiter
        styledText.get_line_delimiter
      end

      def line_at_offset(offset)
        jface_document.get_line_of_offset(offset)
      end

      def offset_at_line(line_ix)
        line_ix = [line_ix, line_count - 1].min
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
        @model.modify_text
      end

      def text=(text)
        @model.verify_text(0, length, text)
        top_pixel   = styledText.getTopPixel
        caret       = cursor_offset
        line        = line_at_offset(caret)
        caret       = caret - offset_at_line(line)

        styledText.setRedraw(false)
        styledText.setText(text)

        unless line > line_count - 1
          # The documents new text is still longer than our previous position, restore position
          line_offset = offset_at_line(line)
          styledText.setCaretOffset([line_offset + caret, offset_at_line(line + 1) - 1].min)
          styledText.setTopPixel(top_pixel)
        end

        styledText.setRedraw(true)
        @model.modify_text
        notify_listeners(:set_text)
      end

      def cursor_offset
        styledText.get_caret_offset
      end

      def selection_offset
        range = styledText.get_selection_range
        range.x == cursor_offset ? range.x + range.y : range.x
      end

      def cursor_offset=(offset)
        styledText.set_caret_offset(offset)
      end

      def selection_range
        range = styledText.get_selection_range
        range.x...(range.x + range.y)
      end

      def selection_ranges
        ranges = styledText.get_selection_ranges
        ranges.to_a.each_slice(2).map do |from, length|
          from...(from + length)
        end
      end

      def set_selection_range(cursor_offset, selection_offset)
        if block_selection_mode?
          start_offset, end_offset = *[cursor_offset, selection_offset].sort
          start_location = styledText.getLocationAtOffset(start_offset)
          end_location   = styledText.getLocationAtOffset(end_offset)
          styledText.set_block_selection_bounds(
            start_location.x,
            start_location.y,
            end_location.x - start_location.x,
            end_location.y - start_location.y + styledText.get_line_height
          )
        else
          styledText.set_selection_range(selection_offset, cursor_offset - selection_offset)
        end
        @model.selection_range_changed(cursor_offset, selection_offset)
      end

      @markStruct ||= Struct.new(:location, :category) # save away the parent class
      class Mark < @markStruct
        def get_offset;      location.get_offset;      end
        def get_line;        location.get_line;        end
        def get_line_offset; location.get_line_offset; end
        def inspect;         "<Mark #{get_line}:#{get_line_offset} (#{get_offset})>"; end
      end

      def create_mark(offset, gravity)
        line = line_at_offset(offset)
        line_offset = offset - offset_at_line(line)
        case gravity
        when :left
          category = "lefts"
        when :right
          category = "rights"
        end
  			location = @swt_mate_document.get_text_location(line, line_offset)
				@swt_mate_document.add_text_location(category, location)
				Mark.new(location, category)
      end

      def delete_mark(mark)
        @swt_mate_document.remove_text_location(mark.category, mark.location)
      end

      def block_selection_mode?
        styledText.get_block_selection
      end

      def block_selection_mode=(bool)
        styledText.set_block_selection(bool)
      end

      def styledText
        @swt_mate_document.mateText.getControl
      end

      def scope_at(line, line_offset)
        @swt_mate_document.mateText.scope_at(line, line_offset)
      end

      class CaretListener
        def initialize(model)
          @model = model
        end

        def caret_moved(event)
          @model.cursor_moved(event.caretOffset)
        end
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
