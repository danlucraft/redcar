
module Redcar
  class EditView < Gtk::SourceView
    extend FreeBASE::StandardPlugin
    extend Redcar::MenuBuilder
    extend Redcar::PreferenceBuilder
    
    def self.load(plugin) #:nodoc:
      Redcar::EditView.init(:bundles_dir => "textmate/Bundles/",
                            :themes_dir  => "textmate/Themes/",
                            :cache_dir   => "cache/")
      Redcar::EditView::Indenter.lookup_indent_rules
      plugin.transition(FreeBASE::LOADED)
    end
    
    def self.start(plugin) #:nodoc:
      Keymap.push_onto(self, "EditView")
      Hook.attach :after_open_window do
        create_grammar_combo
        create_line_col_status
      end
      Hook.attach :after_focus_tab do |tab|
        gtk_combo_box = bus('/gtk/window/statusbar/grammar_combo').data
        gtk_line_label = bus('/gtk/window/statusbar/line').data
        if tab and tab.is_a? EditTab
          list = Redcar::EditView::Grammar.names.sort
          gtk_grammar_combo_box.sensitive = true
          gtk_grammar_combo_box.active = list.index(tab.view.parser.root.grammar.name)
          gtk_line_label.sensitive = true
        else
          gtk_grammar_combo_box.sensitive = false
          gtk_grammar_combo_box.active = -1
          gtk_line_label.sensitive = false
        end
      end
      plugin.transition(FreeBASE::RUNNING)
    end
    
    def self.stop(plugin) #:nodoc:
      Keymap.remove_from(self, "EditView")
      Redcar::EditView::Theme.cache
      plugin.transition(FreeBASE::LOADED)
    end
    
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
        list = Redcar::EditView::Grammar.names.sort
        list.each {|item| gtk_combo_box.append_text(item) }
        gtk_combo_box.signal_connect("changed") do |gtk_combo_box1|
          if tab and tab.is_a? EditTab
            tab.view.change_root_scope(list[gtk_combo_box1.active])
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
    
    class << self
      attr_accessor :bundles_dir, :themes_dir, :cache_dir
    end
    
    def self.init(options)
      @bundles_dir = options[:bundles_dir]
      @themes_dir  = options[:themes_dir]
      @cache_dir   = options[:cache_dir]
      Grammar.load_grammars
      Theme.load_themes
    end
    
    attr_reader :parser
    
    def initialize(options={})
      super()
      set_gtk_cursor_colour
      self.tabs_width = 2
      self.left_margin = 5
      if Redcar::Preference.get("Editing/Wrap words").to_bool
        self.wrap_mode = Gtk::TextTag::WRAP_WORD
      else
        self.wrap_mode = Gtk::TextTag::WRAP_NONE
      end
      setup_buffer(buffer)
      self.show_line_numbers = Redcar::Preference.get("Editing/Show line numbers").to_bool
      set_font(Redcar::Preference.get("Appearance/Tab Font"))
      @theme = Theme.theme(Redcar::Preference.get("Appearance/Tab Theme"))
      setup_bookmark_assets
      connect_signals
      apply_theme
      create_root_scope('Ruby')
      create_parser
      create_indenter
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
      @@bookmark_pixbuf ||= Gdk::Pixbuf.new(Redcar::App.root_path+
                                            '/plugins/redcar_core/icons/bookmark.png')
      set_marker_pixbuf("bookmark", @@bookmark_pixbuf)
    end
    
    def update_line_and_column(mark)
      insert_iter = self.buffer.get_iter_at_mark(mark)
      label = bus('/gtk/window/statusbar/line').data
      label.text = "Line: "+ (insert_iter.line+1).to_s + 
        "   Col: "+(insert_iter.line_offset+1).to_s
    end
    
    def connect_signals
      self.buffer.signal_connect("mark_set") do |widget, event, mark|
        if mark.name == "insert"
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
            view_changed
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
      @root.start_mark = buffer.create_anonymous_mark(buffer.iter(0))
      @root.end_mark   = buffer.create_anonymous_mark(buffer.iter(buffer.char_count))
    end
    
    def create_parser
      raise "trying to create colourer with no theme!" unless @theme
      @colourer = Redcar::EditView::Colourer.new(self, @theme)
      @parser = Parser.new(buffer, @root, [], @colourer)
    end
    
    def create_indenter
      @indenter = Indenter.new(buffer, @parser)
    end
    
    def change_root_scope(gr_name, should_colour=true)
      raise "trying to change to nil grammar!" unless gr_name
      gr = Grammar.grammar(:name => gr_name)
      @root = Scope.new(:pattern => gr,
                        :grammar => gr)
      @root.start_mark = buffer.create_anonymous_mark(buffer.iter(0))
      @root.end_mark   = buffer.create_anonymous_mark(buffer.iter(buffer.char_count))
      @parser.uncolour
      @parser.root = @root
      @parser.reparse
    end
    
    def change_theme(theme_name)
      @theme = Theme.theme(theme_name)
      apply_theme
      new_buffer
      @colourer = Redcar::EditView::Colourer.new(self, @theme)
      @parser.colourer = @colourer
      @parser.recolour
    end
    
    def apply_theme
      background_colour = Theme.parse_colour(@theme.global_settings['background'])
      modify_base(Gtk::STATE_NORMAL, background_colour)
      foreground_colour = Theme.parse_colour(@theme.global_settings['foreground'])
      modify_text(Gtk::STATE_NORMAL, foreground_colour)
      selection_colour  = Theme.parse_colour(@theme.global_settings['selection'])
      modify_base(Gtk::STATE_SELECTED, selection_colour)
    end
    
    def new_buffer
      text = self.buffer.text
      newbuffer = Gtk::SourceBuffer.new
      self.buffer = newbuffer
      setup_buffer(newbuffer)
      newbuffer.text = text
      @parser.buffer = newbuffer
      @indenter.buffer = newbuffer
    end
    
    def setup_buffer(thisbuf)
      thisbuf.check_brackets = false
      thisbuf.highlight = false
      thisbuf.max_undo_levels = 10
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

require 'logger'
unless defined? SyntaxLogger
  SyntaxLogger = Logger.new('syntax.log')
  SyntaxLogger.datetime_format = "%H:%M:%S"
  SyntaxLogger.level = Logger::DEBUG
end

require File.dirname(__FILE__) + '/edit_view/grammar'
require File.dirname(__FILE__) + '/edit_view/scope'
require File.dirname(__FILE__) + '/edit_view/parser'
require File.dirname(__FILE__) + '/edit_view/theme'
require File.dirname(__FILE__) + '/edit_view/colourer'
require File.dirname(__FILE__) + '/edit_view/textloc'
require File.dirname(__FILE__) + '/edit_view/indenter'
require File.dirname(__FILE__) + '/edit_view/ext/syntax_ext'
