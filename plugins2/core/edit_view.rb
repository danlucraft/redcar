
module Redcar
  class EditView < Gtk::SourceView
    extend FreeBASE::StandardPlugin
    extend Redcar::MenuBuilder
    extend Redcar::PreferenceBuilder
    
    def self.load(plugin) #:nodoc:
      Redcar::EditView.init(:bundles_dir => "textmate/Bundles/",
                            :themes_dir  => "textmate/Themes/",
                            :cache_dir   => "cache/")
      plugin.transition(FreeBASE::LOADED)
    end
    
    def self.start(plugin) #:nodoc:
      Keymap.push_onto(self, "EditView")
      plugin.transition(FreeBASE::RUNNING)
    end
    
    def self.stop(plugin) #:nodoc:
      Keymap.remove_from(self, "EditView")
      Redcar::EditView::Theme.cache
      plugin.transition(FreeBASE::LOADED)
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
      create_grammar_combo
      set_gtk_cursor_colour
      self.tabs_width = 2
      self.left_margin = 5
      self.show_line_numbers = Redcar::Preference.get("Editing/Show line numbers").to_bool
      set_font(Redcar::Preference.get("Appearance/Tab Font"))
      @theme = Theme.theme(Redcar::Preference.get("Appearance/Tab Theme"))
      setup_bookmark_assets
      connect_signals
      apply_theme
      create_root_scope('Ruby')
      create_parser
    end

    def create_grammar_combo
# When an EditView is created in a window, this needs to go onto it.
      unless slot = bus('/gtk/window/statusbar/grammar_combo', true)
        gtk_hbox = bus('/gtk/window/statusbar').data
        gtk_combo_box = Gtk::ComboBox.new(true)
        bus('/gtk/window/statusbar/grammar_combo').data = gtk_combo_box
        list = Redcar::EditView::Grammar.names.sort
        list.each {|item| gtk_combo_box.append_text(item) }
        gtk_combo_box.signal_connect("changed") do |gtk_combo_box1|
          tab.view.change_root_scope(list[gtk_combo_box1.active])
        end
        gtk_hbox.pack_end(gtk_combo_box, false)
        gtk_combo_box.show
      end
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
    
    def connect_signals
      signal_connect("parent_set") do
        if parent.is_a? Gtk::ScrolledWindow
          parent.vscrollbar.signal_connect("value_changed") do 
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
    end
    
    def create_parser
      raise "trying to create colourer with no theme!" unless @theme
      @colourer = Redcar::EditView::Colourer.new(self, @theme)
      @parser = Parser.new(buffer, @root, [], @colourer)
    end
    
    def change_root_scope(gr_name, should_colour=true)
      raise "trying to change to nil grammar!" unless gr_name
      gr = Grammar.grammar(:name => gr_name)
      root = Scope.new(:pattern => gr,
                        :grammar => gr,
                        :start => TextLoc(0, 0))
      @parser.root = root
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
      newbuffer.check_brackets = false
      newbuffer.highlight = false
      newbuffer.max_undo_levels = 0
      newbuffer.text = text
      @parser.buffer = newbuffer
    end
    
    def iterize(offset)
      self.buffer.get_iter_at_offset(offset)
    end

    def visible_lines
      [visible_rect.y, visible_rect.y+visible_rect.height].map do |bufy|
        get_line_at_y(bufy)[0].line
      end
    end
    
    def view_changed
      @parser.max_view = visible_lines[1] + 100
    end
  end
end

module Oniguruma #:nodoc:
  class ORegexp #:nodoc:
    def _dump(_)
      self.source
    end
    def self._load(str)
      self.new(str, :options => Oniguruma::OPTION_CAPTURE_GROUP)
    end
  end
end

require 'logger'
unless defined? SyntaxLogger
  SyntaxLogger = Logger.new('syntax.log')
  SyntaxLogger.datetime_format = "%H:%M:%S"
  SyntaxLogger.level = Logger::DEBUG
end

class String
  def delete_slice(range)
    s = range.begin
    e = range.end
    s = self.length + s if s < 0
    e = self.length + e if e < 0
    s, e = e, s if s > e
    first = self[0..(s-1)]
    second = self[(e+1)..-1]
    if s == 0
      first = ""
    end
    if e >= self.length-1
      second = ""
    end
    self.replace(first+second)
    self
  end
end

# C extension
require File.dirname(__FILE__) + '/edit_view/ext/syntax_ext'

require File.dirname(__FILE__) + '/edit_view/grammar'
require File.dirname(__FILE__) + '/edit_view/scope'
require File.dirname(__FILE__) + '/edit_view/parser'
require File.dirname(__FILE__) + '/edit_view/theme'
require File.dirname(__FILE__) + '/edit_view/colourer'
require File.dirname(__FILE__) + '/edit_view/textloc'
require File.dirname(__FILE__) + '/edit_view/fast_enum'
require File.dirname(__FILE__) + '/edit_view/texttab_syntax'
