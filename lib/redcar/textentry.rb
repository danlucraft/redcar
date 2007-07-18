
module Redcar
  class TextEntry
    include Redcar::Undoable
    include UserCommands
    
    #keymap "ctrl a",     :cursor=, :line_start
    #keymap "ctrl e",     :cursor=, :line_end
#     #keymap "Left",   :left
#     #keymap "Right",  :right
#     #keymap "Up",     :up
#     #keymap "Down",   :down
#     #keymap "shift Left",  :shift_left
#     #keymap "shift Right", :shift_right
    #keymap "ctrl z",     :undo
    #keymap "ctrl x",     :cut
    #keymap "ctrl c",     :copy
    #keymap "ctrl v",     :paste
    #keymap "ctrl t",     :transpose
    #keymap "Delete",     :del
    #keymap "BackSpace",  :backspace
#     #keymap "Space",      :insert_at_cursor,  " "
    #keymap "Tab",        :insert_at_cursor,  " "*(Redcar.tab_length||=2)
#     #keymap /^(.)$/,       :insert_at_cursor, '\1'
#     #keymap /^shift (.)$/, :insert_at_cursor, '\1'
#     #keymap /^caps (.)$/,  :insert_at_cursor, '\1'

    user_commands do
      def cursor=(offset)
        to_undo :cursor=, @widget.position
        case offset
        when :line_start
          @widget.position = 0
        when :line_end
          @widget.position = -1
        when Integer
          @widget.position = offset
        end
      end
      
      def left
        @widget.position = [0, @widget.position-1].max
      end
      
      def right
        if @widget.position == @widget.text.length
          @widget.position = -1
        else
          @widget.position = @widget.position+1
        end
      end
      
      def insert_at_cursor(str)
        to_undo :cursor=, @widget.position
        to_undo :delete_text, @widget.position, @widget.position+1
        @widget.insert_text(str, @widget.position)
        @widget.position = @widget.position+1
      end
      
      def delete_text(pos1, pos2)
        to_undo :cursor=, @widget.position
        to_undo :insert_text, pos1, @widget.text[pos1..pos2]
        @widget.delete_text(pos1, pos2)
      end
      
      def insert_text(pos, str)
        to_undo :cursor=, @widget.position
        to_undo :delete_text, pos, pos+str.length
        @widget.insert_text(str, pos)
      end
      
      def del
        delete_text(@widget.position, [@widget.position+1, @widget.text.length].min)
      end
      
      def backspace
        delete_text([@widget.position-1, 0].max, @widget.position)
      end
      
      def shift_right
        current_cursor = @widget.position
        if bounds = @widget.selection_bounds
          if not bounds.include? current_cursor
            right
            new_cursor = @widget.position
            @widget.select_region(current_cursor, new_cursor)
          elsif current_cursor == bounds[0]
            right
            new_cursor = @widget.position
            @widget.select_region(new_cursor, bounds[1])
          elsif current_cursor == bounds[1]
            right
            new_cursor = @widget.position
            @widget.select_region(bounds[0], new_cursor)
          end
        else
          right
          new_cursor = @widget.position
          @widget.select_region(current_cursor, new_cursor)
        end
      end
      
      def shift_left
        current_cursor = @widget.position
        if bounds = @widget.selection_bounds
          if not bounds.include? current_cursor
            left
            new_cursor = @widget.position
            @widget.select_region(new_cursor, current_cursor)
          elsif current_cursor == bounds[0]
            left
            new_cursor = @widget.position
            @widget.select_region(new_cursor, bounds[1])
          elsif current_cursor == bounds[1]
            left
            new_cursor = @widget.position
            @widget.select_region(bounds[0], new_cursor)
          end
        else
          left
          new_cursor = @widget.position
          @widget.select_region(new_cursor, current_cursor)
        end
      end
    end
    
    attr_accessor :widget
    
    def initialize
      @widget = Gtk::Entry.new
      @widget.show
    end
  end
end
