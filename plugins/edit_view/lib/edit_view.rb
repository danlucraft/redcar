
module Redcar
  class EditView < Gtk::Mate::View
    attr_accessor :snippet_inserter, :autocompleter

    def initialize(options={})
      super()
      set_gtk_cursor_colour
      self.buffer = Document.new
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

      self.set_tab_width(Redcar::Preference.get("Editing/Indent size").to_i)
      self.set_insert_spaces_instead_of_tabs(Redcar::Preference.get("Editing/Use spaces instead of tabs").to_bool)
      self.left_margin = 5
      setup_bookmark_assets
      connect_signals
      create_indenter
      create_autopairer
      create_snippet_inserter
      create_autocompleter
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
                                            '/plugins/edit_view/icons/bookmark.png')
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
      buffer.signal_connect("grammar_changed") do |_, grammar_name|
        update_tab_settings_from_grammar(grammar_name)
      end
    end

    def update_tab_settings_from_grammar(grammar_name)
      tab_settings = (Redcar::App["tab_settings"] || {})
      if grammar_tab_settings = tab_settings[grammar_name]
        self.tab_width = grammar_tab_settings["tab_width"]
        self.set_spaces_instead_of_tabs(grammar_tab_settings["spaces_instead_of_tabs"])
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
    
    def create_autocompleter
      @autocompleter = AutoCompleteWord.new(buffer)
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

    def cursor_onscreen?
      visible_lines[0] < buffer.cursor_line and
        buffer.cursor_line < visible_lines[1]
    end

    def tooltip_at_cursor(label)
      rect = get_iter_location(buffer.iter(buffer.cursor_mark))
      x1, y1 = buffer_to_window_coords(Gtk::TextView::WINDOW_WIDGET, rect.x, rect.y)
      x2, y2 = get_window(Gtk::TextView::WINDOW_WIDGET).origin
      Tooltip.new(x1+x2, y1+y2+20, label.strip)
    end
  end
end
