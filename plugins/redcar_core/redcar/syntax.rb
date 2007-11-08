
# A syntax highlighter compatible with textmate bundles.
# Copyright 2007 Daniel Lucraft.

require 'lib/syntax/grammar'
require 'lib/syntax/scope'
require 'lib/syntax/parser'

# Redcar.hook :startup do
#   Redcar::Syntax.load_grammars
#   Redcar.MainToolbar.append_combo(Redcar::Syntax.grammar_names.sort) do |_, tab, grammar|
#     tab.sourceview.set_grammar(Redcar::Syntax.grammar(:name => grammar))
#   end
# end

module Redcar
  module Syntax
    include DebugPrinter
    
    def self.cache_grammars
      if @grammars
        str = Marshal.dump(@grammars)
        File.open("cache/grammars.dump", "w") do |f|
          f.puts str
        end
      end
    end
    
    def self.load_grammars
  #    print "loading grammars ..."
      if File.exist?("cache/grammars.dump")
        str = File.read("cache/grammars.dump")
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
          Dir.glob("textmate/Bundles/*/Syntaxes/*").each do |file|
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
      @grammars
    end
    
    def self.grammar_names
      @grammars.keys
    end
  end
end

module Redcar
  class TextTab
    keymap "super s", :scope_tooltip
    keymap "super-shift S", :select_scope
    keymap "control-super s", :print_scope_tree
    keymap "alt-super s", :reparse_tab
    
    attr_accessor :scope_tree, :parser
    
    def sourceview
      @textview
    end
    
    def reparse_tab
      @textview.colour
      debug_puts @textview.scope_tree.pretty
    end
    
    def print_scope_tree
      puts @textview.scope_tree.pretty
    end
    
    def scope_tooltip
      scope = scope_at_cursor
      puts "scope_at_cursor: #{scope.inspect}"
      inner = scope.pattern and scope.pattern.content_name and
        (cursor_offset >= scope.open_end.offset and 
         (!scope.close_start or cursor_offset < scope.close_start.offset))
      tooltip_at_cursor(scope.hierarchy_names(inner).join("\n"))
    end
    
    def current_scope
      if selected?
        x, y = selection_bounds
        xi = iter(x)
        yi = iter(y)
        scope = Syntax::Scope.common_ancestor(
            @scope_tree.scope_at(TextLoc.new(xi.line, xi.line_offset)),
            @scope_tree.scope_at(TextLoc.new(yi.line, yi.line_offset))
          )
      else
        scope = scope_at_cursor
      end
    end
    
    def current_scope_text
      scope = current_scope
      if scope
        end_iter = iter(scope.end)
        unless scope.end
          end_iter = iter(end_mark)
        end
        self.buffer.get_slice(iter(scope.start), end_iter)
      end
    end
    
    def select_scope
      scope = current_scope
      if scope
        end_iter = iter(scope.end)
        unless scope.end
          end_iter = iter(end_mark)
        end
        select(iter(scope.start), end_iter)
      end
    end
    
    def scope_at_cursor
      if @textview.scope_tree
        scope = @textview.scope_tree.scope_at(TextLoc.new(cursor_line, cursor_line_offset))
      end
    end
  end
  
  class SyntaxSourceView < Gtk::SourceView
    include DebugPrinter
    
#    attr_accessor :buffer
    attr_reader :scope_tree, :parser
    
    def initialize
      super
      set_theme(Theme.default_theme)
    end
    
    def connect_signals
      self.buffer.signal_connect("insert_text") do |widget, iter, text, length|
#         @buffer.signal_emit("inserted_text", iter, text, length)
        Redcar.event :tab_modified, self unless @was_modified
        Redcar.event :tab_changed
        store_insertion(iter, text, length)
        @was_modified = true
        false
      end
      self.buffer.signal_connect("delete_range") do |widget, iter1, iter2|
        Redcar.event :tab_modified, self unless @was_modified
        Redcar.event :tab_changed
        store_deletion(iter1, iter2)
        @was_modified = true
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
      newbuffer.highlight = true
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
      debug_puts "insertion of #{insertion[:lines]} lines from #{insertion[:from]} to #{insertion[:to]}"
      unless $REDCAR_ENV["nonlazy"]
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
      debug_puts "deletion over #{deletion[:lines]} lines from #{deletion[:from]} to #{deletion[:to]}"
      
      unless $REDCAR_ENV["nonlazy"]
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
        debug_puts "parsed and coloured line"
      else
        debug_puts "processing insertion of #{insertion[:lines]} lines"
        @parser.insert(insertion[:from], insertion[:text])
      end
    end
    
    def process_deletion(deletion)
      if deletion[:lines] == 1
        @parser.delete_from_line(deletion[:from].line, 
                                 deletion[:length], 
                                 deletion[:from].offset)
        debug_puts "parsed and coloured line"
      else
        debug_puts "processing deletion of #{deletion[:lines]} lines"
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
        #      debug_puts @scope_tree.pretty
        endt = Time.now
        diff = endt-startt
        debug_puts "time to parse and colour: #{diff}"
      end
    end
  end
end
