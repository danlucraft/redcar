
module Redcar
  class ApplicationSWT
    class ModelessListDialogController

      DEFAULT_HEIGHT_IN_ROWS = 4
      DEFAULT_WIDTH  = 300

      def initialize(model)
        @model  = model
        parent  = ApplicationSWT.display
        @shell  = Swt::Widgets::Shell.new(parent, Swt::SWT::MODELESS)
        @list   = Swt::Widgets::List.new(@shell, Swt::SWT::V_SCROLL | Swt::SWT::SINGLE)
        layout  = Swt::Layout::GridLayout.new(1, true)
        layout.marginHeight    = 0
        layout.marginWidth     = 0
        layout.verticalSpacing = 0
        @shell.setLayout(layout)
        @list.set_layout_data(Swt::Layout::GridData.new(Swt::Layout::GridData::FILL_BOTH))
        @key_listener = KeyListener.new(@model)
        if @model.close_on_lost_focus
          @focus_listener = FocusListener.new(@model)
          @list.add_focus_listener(@focus_listener)
        end
        @list.add_key_listener(@key_listener)
        @shell.pack
        @shell.set_size DEFAULT_WIDTH, convert_to_pixels(DEFAULT_HEIGHT_IN_ROWS)
        attach_listeners
      end

      def set_size(width,height)
        @shell.set_size width, convert_to_pixels(height)
      end

      def convert_to_pixels(rows)
        @list.get_item_height * rows
      end

      def set_location(offset)
        x, y = Swt::GraphicsUtils.below_pixel_location_at_offset(offset)
        @shell.set_location(x,y) if x and y
      end

      # Item at a particular index
      def select(index)
        items = @list.get_items
        if items.size > index and index >= 0
          item = items[index]
          item = item[2,item.length] if item =~ /^(\d)\s.*/
        end
        item
      end

      # The currently selected value
      def selection_value
        @list.get_selection.first
      end

      # Zero-based selected index
      def selection_index
        @list.get_selection_index
      end

      # Close the dialog
      def close
        @list.remove_key_listener(@key_listener)
        @list.remove_focus_listener(@focus_listener) if @focus_listener
        @shell.dispose
      end

      # Open the dialog
      def open
        ApplicationSWT.register_shell(@shell)
        @shell.open
      end

      # Update the list items
      #
      # @param [Array<String>] items
      def update_list(items)
        (0..9).each do |i|
          items[i] = "#{i+1} #{items[i]}" if items.size > i
        end
        @list.set_items items
      end

      def attach_listeners
        @model.add_listener(:open, &method(:open))
        @model.add_listener(:close, &method(:close))
        @model.add_listener(:set_location, &method(:set_location))
        @model.add_listener(:set_size, &method(:set_size))
        @model.add_listener(:update_list, &method(:update_list))
      end

      class KeyListener

        def initialize(model)
          @model = model
        end

        def key_pressed(e)
          case e.keyCode
          when Swt::SWT::CR, Swt::SWT::LF
            index = @model.selection_index
            @model.selected(index)
          when Swt::SWT::ARROW_RIGHT
            items = @model.next_list
            @model.update_list(items) if items
          when Swt::SWT::ARROW_LEFT
            items = @model.previous_list
            @model.update_list(items) if items
          when Swt::SWT::ESC
            @model.close
          else
            (0..9).each do |i|
              if e.keyCode == Swt::SWT.const_get("KEYPAD_#{i}") or
                e.keyCode == i + 48
                @model.selected(i - 1)
                break
              end
            end
          end
        end

        def key_released(e)
        end
      end

      class FocusListener
        def initialize(model)
          @model = model
        end

        def focus_gained(e)
        end

        def focus_lost(e)
          @model.close
        end
      end
    end
  end
end