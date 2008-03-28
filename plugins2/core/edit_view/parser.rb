
$spare_name = "aaaa"

class RedcarSyntaxError < StandardError; end

class Redcar::EditView
  class Parser
    
    attr_accessor :grammars, :root, :colourer, :parse_all
    attr_reader   :max_view
    
    def initialize(buffer, root, grammars=[], colourer=nil)
      @buf = buffer
      @root = root
      @ending_scopes = []
      @grammars = grammars
      @colourer = colourer
      @max_view = 100
      @changes = []
      @scope_last_line = 0
      @parse_all = false
      connect_buffer_signals
      unless @buf.text == ""
        raise "Parser#initialize called with not empty buffer."
      end
    end
    
    def buffer=(buf)
      @buf = buf
      connect_buffer_signals
    end
    
    def connect_buffer_signals
      @buf.signal_connect("insert_text") do |_, iter, text, length|
        if iter.line <= last_line_of_interest
          store_insertion(iter, text, length)
        end
        false
      end
      @buf.signal_connect("delete_range") do |_, iter1, iter2|
        if iter1.line <= last_line_of_interest
          store_deletion(iter1, iter2)
        end
        false
      end
      @buf.signal_connect_after("insert_text") do |_, iter, text, length|
        unless @changes.empty?
          process_changes
        end
        false
      end
      @buf.signal_connect_after("delete_range") do |_, iter1, iter2|
        unless @changes.empty?
          process_changes
        end
        false
      end
    end
    
    def reparse(options=nil)
      @root.children.each {|c| @root.delete_child c }
      lazy_parse_from(0)
    end
    
    def recolour
      raise "no colourer in parser!" unless @colourer
      scopes = nil
      @buf.line_count.times do |line_num|
        scopes = @root.descendants_on_line(line_num)
        SyntaxExt.colour_line_with_scopes(@colourer, @colourer.theme, 
                                          line_num, scopes)
      end
    end
    
    def last_line_of_interest
      if @parse_all
        @buf.line_count
      else
        [@max_view, @scope_last_line].max
      end
    end
    
    def store_insertion(iter, text, length)
      num_lines = text.scan("\n").length+1
      @changes.push({ :type    => :insertion, 
                      :from    => TextLoc.new(iter.line, iter.line_offset),
                      :length  => length,
                      :lines   => num_lines
                    })
    end
    
    def store_deletion(iter1, iter2)
      text = @buf.get_text(iter1, iter2)
      num_lines = text.scan("\n").length+1
      @changes.push({ :type   => :deletion, 
                      :from   => TextLoc(iter1.line, iter1.line_offset),
                      :to     => TextLoc(iter2.line, iter2.line_offset),
                      :length => iter2.offset-iter1.offset,
                      :lines  => num_lines
                    })
    end
    
    def process_changes
#      raise "Queued up changes: oops!" unless @changes.length < 2
      sorted_changes = @changes.sort_by{|h| h[:from]}
      until sorted_changes.empty?
        c = sorted_changes.shift
        process_change c
        @changes.delete c
      end
    end
    
    def process_change(change)
      case change[:type]
      when :insertion
        process_insertion(change)
      when :deletion
        process_deletion(change)
      end
    end
    
    def process_insertion(insertion)
      if insertion[:lines] == 1
        from_iter = @buf.iter(insertion[:from])
        to_tl     = TextLoc(insertion[:from].line,
                            insertion[:from].offset+insertion[:length])
        to_iter   = @buf.iter(to_tl)
        insert_in_line(insertion[:from].line, 
                       @buf.get_text(from_iter, to_iter), 
                       insertion[:from].offset)
      else
        insert(insertion[:from], insertion[:length], insertion[:lines])
      end
    end
    
    def insert_in_line(line_num, text, offset)
      if line_num <= @buf.line_count
        @root.shift_chars(line_num, text.length, offset)
        lazy_parse_from(line_num)
      else
        raise RedcarSyntaxError, "RedcarSyntaxError: trying to insert text in line that"+
          "doesn't exist (#{line_num})"
      end
    end
    
    def insert(loc, length, lines)
      before_scope = scope_at_line_start(loc.line)
      end_offset = @buf.iter(loc).offset+length
      end_iter = @buf.iter(end_offset)
      end_loc  = TextLoc(end_iter.line, end_iter.line_offset)
      @root.shift_after1(loc, lines-1)
      @root.shift_chars(loc.line+lines-1, end_loc.offset-loc.offset, loc.offset)
      lazy_parse_from(loc.line, lines)
    end
    
    def process_deletion(deletion)
      if deletion[:lines] == 1
        delete_from_line(deletion[:from].line, 
                         deletion[:length],
                         deletion[:from].offset)
      else
        delete_between(deletion[:from], deletion[:to])
      end
    end
    
    def delete_from_line(line_num, length, offset)
      if line_num < @buf.line_count
        @root.shift_chars(line_num, -length, offset)
        lazy_parse_from(line_num)
      else
        raise RedcarSyntaxError, "RedcarSyntaxError: trying to delete text from line that"+
          "doesn't exist (#{line_num})"
      end
    end
    
    def delete_between(from, to)
      @root.clear_between_lines(from.line+1, to.line)
      @root.shift_after(from.line+1, -(to.line-from.line))
      
      line_num = from.line
      lazy_parse_from(line_num)
    end
    
    def max_view=(val)
      old_max_view = @max_view
      @max_view = val
      if @max_view > old_max_view and (!@root.last_scope1 or @max_view > @root.last_scope1.end.line)
        lazy_parse_from(old_max_view)
      end
    end
    
    def lazy_parse_from(line_num, at_least=100, options=nil)
      count = 0
      ok = true
      if @parse_all
        until line_num >= @buf.line_count or 
            parse_line(@buf.get_line(line_num), line_num)
          line_num += 1
          count += 1
        end
      else
        until line_num >= @buf.line_count or 
            line_num > last_line_of_interest or
            parse_line(@buf.get_line(line_num), line_num)
          line_num += 1
          count += 1
        end
      end
    end
    
    # Parses line_num, using text line.
    def parse_line(line, line_num)
      print line_num, " "; $stdout.flush
      check_line_exists(line_num)
      @scope_last_line = line_num if line_num > @scope_last_line
      
      lp = LineParser.new(self, line_num, line.string, @ending_scopes[line_num-1])
      
      while lp.any_line_left?
        lp.scan_line
        
        if lp.any_markers?
          lp.process_marker
        else
          lp.clear_line
        end
      end
      
      if @colourer
        remove_tags_from_line(line_num)
        SyntaxExt.colour_line_with_scopes(@colourer, @colourer.theme, 
                                          line_num, lp.all_scopes)
#        debug_print_tag_table
        reset_table_priorities
      end
      
      # should we parse the next line? If we've changed the scope or the 
      # next line has not yet been parsed.
      same = ((@ending_scopes[line_num] == lp.current_scope) and 
              @ending_scopes[line_num+1] != nil)
      @ending_scopes[line_num] = lp.current_scope
      $dp = false
      same
    end
    
    def debug_print_tag_table
      puts "___Tag Table________________"
      @buf.tag_table.each do |tag|
        puts "  #{tag.name}, #{tag.priority}, "+
          "#{tag.foreground_gdk.to_a.map{|v| "%X" % (v/256)}.join("")}"
      end
    end
    
    def remove_tags_from_line(line_num)
      si = @buf.iter(@buf.line_start(line_num))
      ei = @buf.iter(@buf.line_end(line_num))
      all_tags.select {|t| t.name =~ /^EditView/ }.each do |tag|
        @buf.remove_tag(tag, si, ei)
      end
    end
    
    def all_tags
      tt = @buf.tag_table
      tags = []
      tt.each do |tag|
        tags << tag
      end
      tags
    end
    
    def reset_table_priorities
      tags = all_tags.sort_by do |tag|
        tag.edit_view_depth ||= if tag.name
                                  tag.name =~ /\((\d+)\)/
                                  $1.to_i
                                else 
                                  -1
                                end
      end
      tags.each_with_index do |tag, i|
        tag.priority = i
      end
    end
    
    def check_line_exists(line_num)
      unless line_num <= @buf.line_count-1 and line_num >= 0
        raise ArgumentError, "cannot parse line that does not exist"
      end
    end

    class LineParser
      attr_accessor(:pos, :start_scope, :current_scope, :active_grammar,
                    :all_scopes, :closed_scopes, :matching_patterns, :rest_line,
                    :need_new_patterns, :new_scope_markers)
      def initialize(p, line_num, line, opening_scope=nil)
        @parser = p
        @line = line
        @line_num = line_num
        @start_scope = @current_scope = (opening_scope || p.scope_at_line_start(line_num))
        @active_grammar = p.grammar_for_scope(@current_scope)
        @pos = 0
        @all_scopes =  [@current_scope]
        @closed_scopes = []
        @matching_patterns = []
        @rest_line = line
        @need_new_patterns = true
        @new_scope_markers = []
      end
      
      def current_scope_closes?
        if current_scope.closing_regexp
          if md = current_scope.closing_regexp.match(rest_line, pos)
            from = md.begin(0)
            { :from => from, :md => md, :pattern => :close_scope }
          end
        end
      end
      
      def any_line_left?
        pos < @line.length
      end
      
      def get_expected_scope
        expected_scope = current_scope.first_child_after(TextLoc.new(@line_num, pos))
        
        if expected_scope
          expected_scope = nil unless expected_scope.start.line == @line_num
        end
        while expected_scope and expected_scope.capture
          expected_scope = expected_scope.parent
        end
        expected_scope
      end
      
      def need_new_patterns=(v)
        if v
          @matching_patterns = []
        end
        @need_new_patterns = v
      end
      
      def possible_patterns
        if @need_new_patterns
          current_scope.pattern.possible_patterns
        else
          @matching_patterns
        end
      end
      
      def match_pattern(pattern)
        if md = pattern.match.match(@rest_line, pos)
          from = md.begin(0)
          { :from => from, :md => md, :pattern => pattern }
        end
      end
      
      def collect_captures(scope, type)
        case type
        when :end_captures
          matchdata_name = :close_matchdata
        when :begin_captures, :captures
          matchdata_name = :open_matchdata
        end
        if scope.pattern.respond_to? type
          scope.pattern.send(type).each do |num, name|
            md = scope.send(matchdata_name)
            sc = @parser.scope_from_capture(@line_num, num, md)
            if sc
              scope.add_child(sc)
              sc.name = name
              sc.grammar = active_grammar
              sc.capture = true
              closed_scopes << sc
              all_scopes << sc
            end
          end
        end
      end
      
      def close_current_scope(new_scope_marker)
        current_scope.end         = TextLoc.new(@line_num, new_scope_marker[:to])
        current_scope.close_start = TextLoc.new(@line_num, new_scope_marker[:from])
        current_scope.close_matchdata = new_scope_marker[:md]
      end
      
      def new_single_scope(new_scope_marker)
        new_scope = new_scope_marker[:pattern].to_scope
        new_scope.grammar   = active_grammar
        new_scope.start     = TextLoc.new(@line_num, new_scope_marker[:from])
        new_scope.end       = TextLoc.new(@line_num, new_scope_marker[:to])
        new_scope.open_end  = TextLoc.new(@line_num, new_scope_marker[:to])
        new_scope.open_matchdata = new_scope_marker[:md]
        new_scope
      end
      
      def new_double_scope(new_scope_marker)
        pattern = new_scope_marker[:pattern]
        new_scope = pattern.to_scope
        new_scope.grammar = active_grammar
        new_scope.start   = TextLoc.new(@line_num, new_scope_marker[:from])
        new_scope.end     = nil
        new_scope.open_end   = TextLoc.new(@line_num, new_scope_marker[:to])
        new_scope.open_matchdata = new_scope_marker[:md]
        re = Oniguruma::ORegexp.new(@parser.build_closing_regexp(pattern, 
                                                                 new_scope_marker[:md]
                                                                 ), 
                                    :options => Oniguruma::OPTION_CAPTURE_GROUP)
        new_scope.closing_regexp = re
        new_scope
      end
      
      def remove_if_overlaps_with(expected_scope, new_scope)
        if new_scope.overlaps?(expected_scope) or
            new_scope.start > expected_scope.start
          current_scope.delete_child(expected_scope)
        end
      end
      
      def remove_children_that_overlap_with(new_scope)
        current_scope.remove_children_that_overlap(new_scope)
      end
      
      def scan_line
        @new_scope_markers = []
        if close_marker = current_scope_closes?
          @new_scope_markers << close_marker
        end
        possible_patterns.each do |pattern|
          if nsm = match_pattern(pattern)
            @new_scope_markers << nsm
            matching_patterns << pattern if need_new_patterns
          end
        end          
      end
      
      def any_markers?
        @new_scope_markers.length > 0
      end
      
      def get_first_scope_marker
        new_scope_marker = new_scope_markers.sort_by {|sm| sm[:from] }.first
        new_scope_markers.select do |sm|
          sm[:from] == new_scope_marker[:from]
        end.sort_by do |sm|
          sm[:pattern] == :close_scope ? 0 : sm[:pattern].hint
        end.first
      end
      
      def process_marker
#        if @parser.parsed_before?(@line_num)
          expected_scope = get_expected_scope
#        end
        
        new_scope_marker = get_first_scope_marker
        from = new_scope_marker[:from]
        md   = new_scope_marker[:md]
        to   = new_scope_marker[:to] = md.end(0)
        
        case new_scope_marker[:pattern]
        when :close_scope
          if current_scope.end and 
              current_scope.end == TextLoc.new(@line_num, to) and
              current_scope.close_start == TextLoc.new(@line_num, from) and
              current_scope.close_matchdata.to_s == md.to_s
            # we have already parsed this line and this scope ends here
            true
          else
            close_current_scope(new_scope_marker)
            collect_captures(current_scope, :end_captures)
            if expected_scope
              current_scope.delete_child(expected_scope)
            end
          end
          closed_scopes << current_scope
          self.current_scope = current_scope.parent
          all_scopes << current_scope
          self.need_new_patterns = true
        when DoublePattern
          new_scope = new_double_scope(new_scope_marker)
          collect_captures(new_scope, :begin_captures)
          if expected_scope
            # check mod ending scopes as the new one will not have a closing marker
            # but the expected one will:
            if new_scope.surface_identical_modulo_ending?(expected_scope)
              # don't need to do anything as we have already found this,
              # but let's keep the old scope since it will have children and what not.
              new_scope = expected_scope
              expected_scope.each_child {|c| closed_scopes << c}
            else
              remove_if_overlaps_with(expected_scope, new_scope)
              current_scope.add_child(new_scope)
            end
          else
            current_scope.add_child(new_scope)
          end
          all_scopes << new_scope
          self.current_scope = new_scope
          need_new_patterns = true
        when SinglePattern
          new_scope = new_single_scope(new_scope_marker)
          collect_captures(new_scope, :captures)
          
          if expected_scope
            if new_scope.surface_identical?(expected_scope)
              # don't need to do anything
              new_scope = expected_scope
              expected_scope.each_child {|c| closed_scopes << c}
            else  
              remove_if_overlaps_with(expected_scope, new_scope)
              current_scope.add_child(new_scope)
            end
          else
            current_scope.add_child(new_scope)
          end
          remove_children_that_overlap_with(new_scope)
          all_scopes << new_scope
          closed_scopes << new_scope
        end
        self.pos = new_scope_marker[:to]          
      end
      
      def clear_line
        if @parser.parsed_before?(@line_num)
          # If we are reparsing, we might find that some scopes have disappeared,
          # delete them:
          current_scope.root.delete_any_on_line_not_in(@line_num, all_scopes)
          
          # any that we expected to close on this line that now don't?
          #  first build list of scopes that close on this line (including ones
          #  that did but haven't been removed yet).
          scopes_that_closed_on_line = []
          ts = start_scope
          while ts.parent
            if ts.end and ts.end.line == @line_num
              scopes_that_closed_on_line << ts
            end
            ts = ts.parent
          end
          scopes_that_closed_on_line.each do |s|
            unless closed_scopes.include? s
              s.end = nil
              s.close_start = nil
              if s.capture
                s.detach_from_parent
              end
            end
          end
        end
        self.pos = @line.length + 1          
      end
    end
    
    def clear_after(line_num)
      @root.clear_after(TextLoc.new(line_num, 0))
      if line_num == 0
        @ending_scopes = []
      else
        @ending_scopes = @ending_scopes[0..(line_num-1)]
      end
    end
    
    def clear_line(line)
      @root.clear_between_lines(line, line)
    end
    
    def clear_between_lines(line_from, line_to)
      @root.clear_between_lines(line_from, line_to)
    end
    
    def scope_at(loc)
      @root.scope_at(loc)
    end
    
    def scope_at_line_start(num)
      @root.line_start(num)
    end
    
    def scope_at_line_end(num)
      @root.line_end(num)
    end
    
    # ..oO0# UNCLEAN #0Oo..
    
    def add_line(line)
      add_line_info(line)
      parse_line(line, @text.length-1)
    end
    
    def insert_line(line, line_num)
      @text.insert(line_num, line)
      @fold_counts.insert(line_num, 0)
      @ending_scopes.insert(line_num, nil)
      shift_after(line_num, 1)
      parse_line(line, line_num)
      if (line_num > 0 and @ending_scopes[line_num] != @ending_scopes[line_num-1]) or
          (line_num == 0 and @ending_scopes[line_num] != @root)
        line_num += 1
        lazy_parse_from(line_num)
      end
    end
    
    def string_to_lines(text)
      lines = text.split("\n")
      lines << "" if text[-1..-1] == "\n"
      lines << "" if text == "\n"
      lines
    end
    
    def scope_at_end_of(num)
      @root.scope_at(TextLoc.new(num, @text[num].length))
    end
    
#     def parse_from(num)
#       @root.clear_after(TextLoc.new(num, 0))
#       (num).upto([@text.length-1, @max_parse_line].min) do |i|
#         clear_line(line_num)
#         parse_line(@text[i], i)
#       end
#     end

    def max_parse_line=(v)
      @max_parse_line = v
    end
    
    def shift_after(line, amount)
      @root.shift_after(line, amount)
    end
    
    def parsed_before?(line_num)
      @ending_scopes[line_num]
    end
    
    def scope_from_capture(line_num, num, md)
      num = num.to_i
      capture = get_capture(num, md)
      unless capture == ""
        from = md.begin(num)
        to   = md.end(num)
        ::Redcar::EditView::Scope.create2(::Redcar::EditView::TextLoc.new(line_num, from), 
                                          ::Redcar::EditView::TextLoc.new(line_num, to))
      end
    end
    
    def grammar_for_scope(scope_name)
      if scope_name.respond_to? :grammar
        scope_name.grammar
      else
        @grammars.find do |gr|
          gr.scope_name == scope_name
        end
      end
    end
    
    def build_closing_regexp(pattern, md)
      new_end = pattern.end.gsub(/\\([0-9]+)/) do
        md.captures.send(:[], $1.to_i-1)
      end
    end

    def get_capture(capture_index, md)
      if capture_index == 0
        md.to_s
      else
        md.captures[capture_index-1] || ""
      end
    end
  end
end
