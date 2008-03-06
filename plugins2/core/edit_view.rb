
module Redcar
  class EditView < Gtk::SourceView
    extend FreeBASE::StandardPlugin
    extend Redcar::CommandBuilder
    extend Redcar::MenuBuilder
    
    def self.load(plugin)
      Redcar::EditView.init(:bundles_dir => "textmate/Bundles/",
                            :themes_dir  => "textmate/Themes/",
                            :cache_dir   => "cache/")
      plugin.transition(FreeBASE::LOADED)
    end
    
    def self.start(plugin)
      Keymap.push_onto(self, "EditView")
      plugin.transition(FreeBASE::RUNNING)
    end
    
    def self.stop(plugin)
      Keymap.remove_from(self, "EditView")
      plugin.transition(FreeBASE::LOADED)
    end
    
    def self.start(plugin)
# When an EditView is created in a window, this needs to go onto it.
#       gtk_hbox = bus('/gtk/window/statusbar').data
#       gtk_combo_box = Gtk::ComboBox.new(true)
#       list = Redcar::EditView.grammar_names.sort
#       list.each {|item| gtk_combo_box.append_text(item) }
#       gtk_combo_box.signal_connect("changed") do |gtk_combo_box1|
#         tab.sourceview.set_grammar(Redcar::EditView.grammar(:name => list[gtk_combo_box1.active]))
#       end
#       gtk_hbox.pack_end(gtk_combo_box, false)
#       gtk_combo_box.show
      
      plugin.transition(FreeBASE::RUNNING)
    end
    
    class << self
      attr_accessor :bundles_dir, :themes_dir, :cache_dir
    end
    
    def self.init(options)
      @bundles_dir = options[:bundles_dir]
      @themes_dir = options[:themes_dir]
      @cache_dir   = options[:cache_dir]
      load_grammars unless @grammars
      Redcar::Theme.load_themes unless Redcar::Theme.themes
    end
    
    def self.cache_grammars
      if @grammars
        str = Marshal.dump(@grammars)
        File.open(@cache_dir + "grammars.dump", "w") do |f|
          f.puts str
        end
      end
    end
    
    def self.load_grammars
      if File.exist?(@cache_dir + "grammars.dump")
        str = File.read(@cache_dir + "grammars.dump")
        @grammars = Marshal.load(str)
        @grammars_by_extension ||= {}
        @grammars.each do |name, gr|
          (gr.file_types||[]).each do |ext|
            @grammars_by_extension["."+ext] = @grammars[name]
          end
        end
      else
        @grammars ||= {}
        @grammars_by_extension ||= {}
        plists = []
        if @grammars.keys.empty?
          Dir.glob(@bundles_dir + "*/Syntaxes/*").each do |file|
            if %w(.plist .tmLanguage).include? File.extname(file)
              begin
                puts "loading #{file}"
                xml = IO.readlines(file).join
                plist = Redcar::Plist.plist_from_xml(xml)
                gr = plist[0]
                plists << plist
                @grammars[gr['name']] = Grammar.new(plist[0])
                (gr['fileTypes'] || []).each do |ext|
                  @grammars_by_extension["."+ext] = @grammars[gr['name']]
                end
              rescue => e
                puts "failed to load syntax: #{file}"
                puts e.message
              end
            end
          end
          self.cache_grammars
        end
      end
    end
    
    def self.grammar(options)
      if options[:name]
        @grammars[options[:name]]
      elsif options[:extension]
        @grammars_by_extension[options[:extension]]
      elsif options[:first_line]
        @grammars.each do |name, gr|
          if gr.first_line_match and options[:first_line] =~ gr.first_line_match
            return gr 
          end
        end
        nil
      elsif options[:scope]
        @grammars.each do |_, gr|
          if gr.scope_name == options[:scope]
            return gr
          end
        end
        nil
      end
    end
    
    def self.grammars
      load_grammars unless @grammars
      @grammars
    end
    
    def self.grammar_names
      load_grammars unless @grammars
      @grammars.keys
    end
    
    attr_reader :scope_tree, :parser
    
    def initialize(options={})
      super()
      @parsed_upto = -1
#       set_theme(Theme.theme(bus("/redcar/preferences/Appearance/Tab Theme").data), false)
#       modify_font(Pango::FontDescription.new("Monospace 12"))
      self.tabs_width = 2
      connect_signals
      set_grammar(EditView.grammar(:name => 'Ruby'), false)
      parse_upto(visible_lines.last+50)
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
      parse_upto visible_lines[1] + 50
    end
    
    def parse_upto(line_num)
      puts "parsing upto: #{line_num}-#{@parsed_upto}"
      return unless @parser
      if line_num > @parsed_upto
        s = buffer.get_iter_at_line(@parsed_upto)
        e = buffer.get_iter_at_line(line_num+1)
        @parser.max_parse_line = line_num
        @parser.add_lines(buffer.get_text(s, e).chomp)
        @parsed_upto = line_num+1
      end
    end
    
    def connect_signals
      @insertion = []
      @deletion = []
      self.buffer.signal_connect("insert_text") do |widget, iter, text, length|
        if iter.line <= @parsed_upto
          store_insertion(iter, text, length)
        end
        false
      end
      self.buffer.signal_connect("delete_range") do |widget, iter1, iter2|
        if iter1.line <= @parsed_upto
          store_deletion(iter1, iter2)
        end
        false
      end
      self.buffer.signal_connect_after("insert_text") do |widget, iter, text, length|
        if iter.line <= @parsed_upto
          process_operation
        end
        false
      end
      self.buffer.signal_connect_after("delete_range") do |widget, iter1, iter2|
        if iter1.line <= @parsed_upto
          process_operation
        end
        false
      end
      @no_colouring = false
      @operations = []
    end
    
    def new_buffer
      text = self.buffer.text
      newbuffer = Gtk::SourceBuffer.new
      self.buffer = newbuffer
      newbuffer.check_brackets = false
      newbuffer.highlight = false
      newbuffer.max_undo_levels = 0
      newbuffer.text = text
      connect_signals
    end
    
    def set_theme(th, should_colour=true)
      if th
        apply_theme(th)
        @colr = Redcar::Colourer.new(self, th)
        if @parser
          @parser.colourer = @colr
        end
        new_buffer
        @parsed_upto = 0
        @parser.clear_after(0) if @parser
        @parser.max_parse_line = 0 if @parser
        parse_upto visible_lines[1]+50
      else
        raise StandardError, "nil theme passed to set_theme"
      end
    end
    
    def set_syntax(name)
      set_grammar(EditView.grammar(:name => name))
    end
    
    def grammar
      @grammar
    end
    
    def grammar=(gr)
      set_grammar(gr)
    end
    
    def set_grammar(gr, should_colour=true)
      if gr
        @grammar = gr
        SyntaxLogger.debug { "setting grammar: #{@grammar.name}" }
        @scope_tree = Scope.new(:pattern => gr,
                                :grammar => gr,
                                :start => TextLoc.new(0, 0))
        @parser = Parser.new(@scope_tree, [gr], "", @colr)
        @operations.clear
        colour if should_colour
      else
        @grammar = nil
        @scope_tree = nil
        @parser = nil
      end
    end
    
    def language
      return @grammar.name if @grammar
    end
    
    def apply_theme(theme)
      background_colour = Theme.parse_colour(theme.global_settings['background'])
      modify_base(Gtk::STATE_NORMAL, background_colour)
      foreground_colour = Theme.parse_colour(theme.global_settings['foreground'])
      modify_text(Gtk::STATE_NORMAL, foreground_colour)
      selection_colour  = Theme.parse_colour(theme.global_settings['selection'])
      modify_base(Gtk::STATE_SELECTED, selection_colour)
    end
    
    def no_colouring
      @no_colouring = true
      yield
      @no_colouring = false
    end
    
    def store_insertion(iter, text, length)
      return if @no_colouring
      iter2 = self.buffer.get_iter_at_offset(iter.offset+length)
      @count ||= 1
      insertion = {}
      insertion[:type] = :insertion
      insertion[:from] = TextLoc.new(iter.line,  iter.line_offset)
      insertion[:to]   = TextLoc.new(iter2.line, iter2.line_offset)
      insertion[:text] = text
      insertion[:lines] = text.scan("\n").length+1
      insertion[:count] = @count
      @count += 1
      @operations << insertion
      SyntaxLogger.debug {"insertion of #{insertion[:lines]} lines from #{insertion[:from]} to #{insertion[:to]}"}
    end
    
    def store_deletion(iter1, iter2)
      return if @no_colouring
      @count ||= 1
      deletion = {}
      deletion[:type] = :deletion
      deletion[:from] = TextLoc.new(iter1.line, iter1.line_offset)
      deletion[:to]   = TextLoc.new(iter2.line, iter2.line_offset)
      deletion[:lines] = iter2.line-iter1.line+1
      deletion[:length] = iter2.offset-iter1.offset
      deletion[:count] = @count
      @count += 1
      
      @operations << deletion
      SyntaxLogger.debug { "deletion over #{deletion[:lines]} lines from #{deletion[:from]} to #{deletion[:to]}" }
      
#       unless $REDCAR_ENV and $REDCAR_ENV["nonlazy"]
#         Gtk.idle_add do
#           process_operation
#         end
#       else
        process_operation
#       end
    end
    
    def syntax?
      @grammar and @scope_tree and @parser and @colr
    end
    
    def process_operation
      unless @operations.empty?
        operation = @operations.shift
        if syntax?
          case operation[:type]
          when :insertion
            process_insertion(operation)
          when :deletion
            process_deletion(operation)
          end
        end
      end
    end
    
    def num_lines
      @parser.text.length
    end
    
    def process_insertion(insertion)
      if insertion[:lines] == 1
        @parser.insert_in_line(insertion[:from].line, 
                               insertion[:text], 
                               insertion[:from].offset)
        SyntaxLogger.debug{ "parsed and coloured line" }
      else
        SyntaxLogger.debug{ "processing insertion of #{insertion[:lines]} lines" }
        @parser.insert(insertion[:from], insertion[:text])
      end
      @parsed_upto = [@parsed_upto, @parser.text.length-1].min
      @parser.max_parse_line = @parsed_upto
    end
    
    def process_deletion(deletion)
      if deletion[:lines] == 1
        @parser.delete_from_line(deletion[:from].line, 
                                 deletion[:length], 
                                 deletion[:from].offset)
      else
        @parser.delete_between(deletion[:from], deletion[:to])
      end
      @parsed_upto = [@parsed_upto, @parser.text.length-1].min
      @parser.max_parse_line = @parsed_upto
    end
    
    def colour
      if syntax?
        startt = Time.now
        @parser.clear_after(0)
        start_iter, end_iter = self.buffer.bounds
        self.buffer.remove_all_tags(start_iter, end_iter)
        @parsed_upto = 0
        @parser.max_parse_line = @parsed_upto
        if @parsed_upto == 0 and visible_lines[1] > 50
          n = 100
        else
          n = visible_lines[1]+50
        end
        parse_upto n
        endt = Time.now
        diff = endt-startt
      end
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
