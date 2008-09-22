
module Redcar
  class EditView < Gtk::Mate::View
    def self.create_line_col_status
      unless slot = bus('/gtk/window/statusbar/line', true)
        gtk_hbox = bus('/gtk/window/statusbar').data
        gtk_label = Gtk::Label.new("")
        bus('/gtk/window/statusbar/line').data = gtk_label
        gtk_hbox.pack_end(gtk_label, false)
        gtk_label.set_padding 10, 0
        gtk_label.show
      end
    end

    def self.create_grammar_combo
      # When an EditView is created in a window, this needs to go onto it.
      unless slot = bus('/gtk/window/statusbar/grammar_combo', true)
        gtk_hbox = bus('/gtk/window/statusbar').data
        gtk_combo_box = Gtk::ComboBox.new(true)
        bus('/gtk/window/statusbar/grammar_combo').data = gtk_combo_box
        Gtk::Mate.load_bundles
        list = Gtk::Mate::Buffer.bundles.map{|b| b.grammars }.flatten.map(&:name).sort
        list.each {|item| gtk_combo_box.append_text(item) }
        gtk_combo_box.signal_connect("changed") do |gtk_combo_box1|
          if Redcar.tab and Redcar.tab.class.to_s == "EditTab"
            Redcar.tab.view.change_root_scope(list[gtk_combo_box1.active])
          end
        end
        gtk_hbox.pack_end(gtk_combo_box, false)
        gtk_combo_box.sensitive = false
        gtk_combo_box.show
      end
    end

    def self.gtk_grammar_combo_box
      bus('/gtk/window/statusbar/grammar_combo', true).data
    end

    attr_accessor :snippet_inserter

    def initialize(options={})
      super()
      set_gtk_cursor_colour
      self.buffer = Gtk::Mate::Buffer.new
      self.modify_font(Pango::FontDescription.new(Redcar::Preference.get("Appearance/Tab Font")))
      self.buffer.set_grammar_by_name("Ruby")
      h = self.signal_connect_after("expose-event") do |_, ev|
        if ev.window == self.window
          self.set_theme_by_name(Redcar::Preference.get("Appearance/Tab Theme"))
          self.signal_handler_disconnect(h)
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

    def update_line_and_column(mark)
      insert_iter = self.buffer.get_iter_at_mark(mark)
      label = bus('/gtk/window/statusbar/line').data
      label.text = "Line: "+ (insert_iter.line+1).to_s +
        "   Col: "+(insert_iter.line_offset+1).to_s
    end

    def connect_signals
      self.buffer.signal_connect("mark_set") do |widget, event, mark|
        if !buffer.ignore_marks and mark == buffer.cursor_mark
          update_line_and_column(mark)
        end
        false
      end

      self.buffer.signal_connect("changed") do |widget, event|
        mark = self.buffer.cursor_mark
        update_line_and_column(mark)
        false
      end

      # Hook up to scrollbar changes for the parser
      signal_connect("parent_set") do
        if parent.is_a? Gtk::ScrolledWindow
          parent.vscrollbar.signal_connect_after("value_changed") do
#            view_changed
          end
        end
      end
    end

    def set_font(font)
      modify_font(Pango::FontDescription.new(font))
    end

    def create_root_scope(name)
      grammar = Grammar.grammar(:name => name)
      raise "no such grammar: #{name}" unless grammar
      @root = Scope.new(:pattern => grammar,
                        :grammar => grammar,
                        :start => TextLoc(0, 0))
      @root.bg_color = @theme.global_settings['background']
      @root.set_start_mark buffer, buffer.iter(0).offset, false
      @root.set_end_mark   buffer, buffer.char_count, false
      @root.set_open(true)
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

    def view_changed
#      puts "last_visible_line:#{last_visible_line}"
      @parser.max_view = last_visible_line + 100
    end

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
