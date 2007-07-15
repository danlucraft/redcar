
# A SourceView widget compatible with textmate syntax definitions.
# Copyright 2007 Daniel Lucraft.

require 'gtksourceview'
require 'oniguruma'
module Oniguruma
  class ORegexp
    def _dump(_)
      self.source
    end
    def self._load(str)
      self.new(str, :options => Oniguruma::OPTION_CAPTURE_GROUP)
    end
  end
end

require File.dirname(__FILE__) + '/grammar'
require File.dirname(__FILE__) + '/scope'
require File.dirname(__FILE__) + '/parser'
require File.dirname(__FILE__) + '/theme'
require File.dirname(__FILE__) + '/colourer'
require File.dirname(__FILE__) + '/textloc'
require File.dirname(__FILE__) + '/fast_enum'

module Redcar
  class SyntaxSourceView < Gtk::SourceView
    class << self
      attr_accessor :bundles_dir, :themes_dir, :cache_dir
      
      def init(options)
        @bundles_dir = options[:bundles_dir]
        @themes_dir = options[:themes_dir]
        @cache_dir   = options[:cache_dir]
        load_grammars unless @grammars
        Redcar::Theme.load_themes unless Redcar::Theme.themes
      end
      
      def cache_grammars
        if @grammars
          str = Marshal.dump(@grammars)
          File.open(@cache_dir + "grammars.dump", "w") do |f|
            f.puts str
          end
        end
      end
      
      def load_grammars
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
                  @grammars[gr['name']] = Redcar::Syntax::Grammar.new(plist[0])
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
        #  puts "done"
      end
      
      def grammar(options)
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
      
      def grammars
        load_grammars unless @grammars
        @grammars
      end
      
      def grammar_names
        load_grammars unless @grammars
        @grammars.keys
      end
    end
    
    attr_reader :scope_tree, :parser
    
    def initialize(options={})
      super()
      unless SyntaxSourceView.bundles_dir
        if options[:bundles_dir]
          SyntaxSourceView.init(options)
        else
          raise ArgumentError, "SyntaxSourceView.new expects :bundle_dir, :themes_dir and (optionally) :cache_dir."
        end
      end
      set_theme(Theme.default_theme)
      modify_font(Pango::FontDescription.new("Monospace 12"))
      self.tabs_width = 2
      set_grammar(SyntaxSourceView.grammar(:name => 'Ruby'))
    end
    
    def connect_signals
      self.buffer.signal_connect("insert_text") do |widget, iter, text, length|
        store_insertion(iter, text, length)
        false
      end
      self.buffer.signal_connect("delete_range") do |widget, iter1, iter2|
        store_deletion(iter1, iter2)
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
    
    def set_theme(th)
      if th
        apply_theme(th)
        @colr = Redcar::Colourer.new(self, th)
        if @parser
          @parser.colourer = @colr
        end
        new_buffer
        colour
      else
        raise StandardError, "nil theme passed to set_theme"
      end
    end
    
    def set_syntax(name)
      set_grammar(Syntax.grammar(:name => name))
    end
    
    def grammar
      @grammar
    end
    
    def grammar=(gr)
      set_grammar(gr)
    end
    
    def set_grammar(gr)
      if gr and @grammar != gr
        @grammar = gr
     #   puts "setting grammar: #{@grammar.name}"
        @scope_tree = Redcar::Syntax::Scope.new(:pattern => gr,
                                                :grammar => gr,
                                                :start => TextLoc.new(0, 0))
        @parser = Redcar::Syntax::Parser.new(@scope_tree, [gr], "", @colr)
        @operations.clear
        colour
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
      #debug_puts "insertion of #{insertion[:lines]} lines from #{insertion[:from]} to #{insertion[:to]}"
      unless $REDCAR_ENV and $REDCAR_ENV["nonlazy"]
        Gtk.idle_add do
          process_operation
        end
      else
        process_operation
      end
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
      #debug_puts "deletion over #{deletion[:lines]} lines from #{deletion[:from]} to #{deletion[:to]}"
      
      unless $REDCAR_ENV and $REDCAR_ENV["nonlazy"]
        Gtk.idle_add do
          process_operation
        end
      else
        process_operation
      end
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
        #debug_puts "parsed and coloured line"
      else
        #debug_puts "processing insertion of #{insertion[:lines]} lines"
        @parser.insert(insertion[:from], insertion[:text])
      end
    end
    
    def process_deletion(deletion)
      if deletion[:lines] == 1
        @parser.delete_from_line(deletion[:from].line, 
                                 deletion[:length], 
                                 deletion[:from].offset)
        #debug_puts "parsed and coloured line"
      else
        #debug_puts "processing deletion of #{deletion[:lines]} lines"
        @parser.delete_between(deletion[:from], deletion[:to])
      end
    end
    
    def colour
      if syntax?
        startt = Time.now
        @parser.clear_after(0)
        start_iter, end_iter = self.buffer.bounds
        self.buffer.remove_all_tags(start_iter, end_iter)
        @parser.add_lines(self.buffer.text, :lazy => true)
        #      #debug_puts @scope_tree.pretty
        endt = Time.now
        diff = endt-startt
#        #debug_puts "time to parse and colour: #{diff}"
      end
    end
  end
end

module Redcar
#   class TextTab
#   end
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
