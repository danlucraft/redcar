
module Redcar
  class EditView < Gtk::Mate::View
    attr_accessor :snippet_inserter

    def initialize(options={})
      super()
      set_gtk_cursor_colour
      self.buffer = Gtk::Mate::Buffer.new
      self.modify_font(Pango::FontDescription.new(Redcar::Preference.get("Appearance/Tab Font")))
      h = self.signal_connect_after("expose-event") do |_, ev|
        if ev.window == self.window
          if self.buffer.parser
            self.set_theme_by_name(Redcar::Preference.get("Appearance/Tab Theme"))
            self.signal_handler_disconnect(h)
          end
        end
      end
      @modified = false
      if Redcar::Preference.get("Editing/Wrap words").to_bool
        self.wrap_mode = Gtk::TextTag::WRAP_WORD
      else
        self.wrap_mode = Gtk::TextTag::WRAP_NONE
      end
      self.left_margin = 5
      self.show_line_numbers = Redcar::Preference.get("Editing/Show line numbers").to_bool

      self.set_tab_width(2)
      self.left_margin = 5
      setup_buffer(buffer)
      setup_bookmark_assets
      connect_signals
      create_indenter
      create_autopairer
      create_snippet_inserter
    end

    def set_gtk_cursor_colour
      Gtk::RC.parse_string(<<-EOR)
    style "green-cursor" {
      GtkTextView::cursor-color = "grey"
    }
    class "GtkWidget" style "green-cursor"
      EOR
    end

    def setup_bookmark_assets
      @@bookmark_pixbuf ||= Gdk::Pixbuf.new(Redcar::ROOT+
                                            '/plugins/redcar_core/icons/bookmark.png')
#      set_marker_pixbuf("bookmark", @@bookmark_pixbuf)
    end

    def connect_signals
      # Hook up to scrollbar changes for the parser
      signal_connect("parent_set") do
        if parent.is_a? Gtk::ScrolledWindow
          parent.vscrollbar.signal_connect_after("value_changed") do
            @scroll_changed = true
          end
        end
      end
      signal_connect("expose_event") do
        if @scroll_changed
          @scroll_changed = false
          value_changed_handler
        end
      end
    end

    def set_font(font)
      modify_font(Pango::FontDescription.new(font))
    end

    def create_indenter
      @indenter = Indenter.new(buffer)
    end

    def create_autopairer
      @autopairer = AutoPairer.new(buffer)
    end

    def create_snippet_inserter
      @snippet_inserter = SnippetInserter.new(buffer)
    end

#     def new_buffer
#       text = self.buffer.text
#       newbuffer = Gtk::SourceBuffer.new
#       self.buffer = newbuffer
#       setup_buffer(newbuffer)
#       newbuffer.text = text
#       newbuffer.parser = @parser
#       @parser.buffer = newbuffer
#       @indenter.buffer = newbuffer
#       @autopairer.buffer = newbuffer
#     end

    def setup_buffer(thisbuf)
#       thisbuf.check_brackets = false
#       thisbuf.highlight = false
#       thisbuf.max_undo_levels = 10
    end

    def indent_line(line_num)
      @indenter.indent_line(line_num)
    end

    def iterize(offset)
      self.buffer.get_iter_at_offset(offset)
    end

    def visible_lines
      [visible_rect.y, visible_rect.y+visible_rect.height].map do |bufy|
        get_line_at_y(bufy)[0].line
      end
    end

    def last_visible_line
      bufy = visible_rect.y+visible_rect.height
      get_line_at_y(bufy)[0].line
    end

#     def view_changed
# #      puts "last_visible_line:#{last_visible_line}"
#       @parser.max_view = last_visible_line + 100
#     end

    def cursor_onscreen?
      visible_lines[0] < buffer.cursor_line and
        buffer.cursor_line < visible_lines[1]
    end

    def tooltip_at_cursor(label)
      rect = get_iter_location(buffer.iter(buffer.cursor_mark))
      x1, y1 = buffer_to_window_coords(Gtk::TextView::WINDOW_WIDGET, rect.x, rect.y)
      x2, y2 = get_window(Gtk::TextView::WINDOW_WIDGET).origin
      Tooltip.new(x1+x2, y1+y2+20, label)
    end
  end
end

# require File.dirname(__FILE__) + '/edit_view/grammar'
# require File.dirname(__FILE__) + '/edit_view/scope'
# require File.dirname(__FILE__) + '/edit_view/parser'
# require File.dirname(__FILE__) + '/edit_view/theme'
# require File.dirname(__FILE__) + '/edit_view/colourer'
# require File.dirname(__FILE__) + '/edit_view/textloc'

# require File.dirname(__FILE__) + '/edit_view/ext/redcar_ext'
