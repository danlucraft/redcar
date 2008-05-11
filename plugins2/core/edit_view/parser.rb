
$spare_name = "aaaa"

class RedcarSyntaxError < StandardError; end

class Redcar::EditView
  class Parser
    create_logger
    
    class << self
      attr_accessor :logger
    end
    
    attr_accessor :grammars, :root, :colourer, :parse_all, :parsing_on
    attr_reader   :max_view, :buf, :ending_scopes, :starting_scopes

    def initialize(buffer, root, grammars=[], colourer=nil)
      buffer.parser = self
      @buf = buffer
      @root = root
      @grammars = grammars
      @colourer = colourer
      @max_view = 200
      @changes = []
      @scope_last_line = 0
      @parse_all = true
      @cursor_line = 0
      @parsing_on = true
      @delay_count = 0
      @tags = []

      # line scope trackers
      @ending_scopes = []
      @starting_scopes = []
      @last_childs = []

      connect_buffer_signals
      unless @buf.text == ""
        raise "Parser#initialize called with not empty buffer."
      end
    end

    def delay_parsing
      @parsing_on = false
      yield
      @parsing_on = true
      process_changes if @delay_count == 0
    end

    def stop_parsing
      @delay_count += 1
      @parsing_on = false
    end

    def start_parsing
      @delay_count -= 1
      @delay_count = 0 if @delay_count < 0
      if @delay_count == 0
        @parsing_on = true
        process_changes
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
        if !@changes.empty? and @parsing_on
          process_changes
        end
        false
      end
      @buf.signal_connect_after("delete_range") do |_, iter1, iter2|
        if !@changes.empty? and @parsing_on
          process_changes
        end
        false
      end
      @buf.tag_table.signal_connect_after("tag_added") do |_, tag|
        if tag.name =~ /^EditView\((\d+)\)/
          @tags << tag
        end
        reset_table_priorities
      end
    end

    def reparse(options=nil)
      @root.children.each {|c| @root.delete_child c }
      parse_from(0)
    end

    def recolour
      raise "no colourer in parser!" unless @colourer
      scopes = nil
      @buf.line_count.times do |line_num|
        scopes = @root.descendants_on_line(line_num)
        SyntaxExt.colour_line_with_scopes(@buf, @colourer.theme, scopes)
      end
    end

    def uncolour
      SyntaxExt.uncolour_scopes(@colourer, [@root])
    end

    def last_line_of_interest
      if @parse_all
        @buf.line_count
      else
        @max_view
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
      changed_lines = []
      while change = @changes.shift
        changed_lines << update_line_scope_trackers(change)
      end
      changed_lines.sort!
      while pair = changed_lines.shift
        from_line = pair[0]
        num_lines = pair[1]
        parse_from(from_line, num_lines-1)
        changed_lines.reject! do |from, n|
          from <= from_line+num_lines and
            from+n <= from_line+num_lines
        end
      end
    end

    def update_line_scope_trackers(change)
      case change[:type]
      when :insertion
        loc, lines = change[:from], change[:lines]
        (lines-1).times do
          @ending_scopes.insert(loc.line, nil)
          @starting_scopes.insert(loc.line, nil)
          @last_childs.insert(loc.line, nil)
        end
        [loc.line, lines]
      when :deletion
        from, to = change[:from], change[:to]
        (to.line-from.line-1).times do
          @ending_scopes.delete_at(from.line)
          @starting_scopes.delete_at(from.line)
          @last_childs.delete_at(from.line)
        end
        [from.line, 1]
      end
    end

    def process_insertion(insertion)
      parse_from(loc.line, lines)
    end

    def process_deletion(deletion)
      parse_from(line_num)
    end

    def max_view=(val)
      old_max_view = @max_view
      @max_view = val
#      puts "max_view=(#{val}) [old: #{old_max_view}, scope_last_line:#{@scope_last_line}]"
      if @max_view > old_max_view and
          (@max_view > @scope_last_line)
        parse_from(@scope_last_line+1)
      end
    end

    def parse_from(line_num, at_least=0, options=nil)
      count = 0
      ok = true
      if @parse_all
        until line_num >= @buf.line_count or
            (parse_line(line_num) and
             count >= at_least)
          line_num += 1
          count += 1
        end
      else
        until line_num >= @buf.line_count or
            line_num > last_line_of_interest or
            (parse_line(line_num) and
             count >= at_least)
          line_num += 1
          count += 1
        end
        if @ending_scopes[line_num-1] != @starting_scopes[line_num]
          clear_after(line_num)
        end
      end
      $stdout.flush
    end

    def num_marks
      i = 0
      ObjectSpace.each_object(Gtk::TextMark) do |obj|
        puts "mark<#{obj.object_id}>: #{obj.name.inspect}"
        i += 1
      end
      i
    end
    
    def num_scopes
      i = 0
      ObjectSpace.each_object(Redcar::EditView::Scope) do |obj|
        i += 1
      end
      i
    end
    
    # Parses line_num, using text line.
    def parse_line(line_num)
#      Parser.logger.info "parsing line: #{line_num} (in thread: #{Thread.current})"
#      line = @buf.get_line(line_num)
      line = @buf.get_slice(@buf.line_start(line_num), @buf.line_end(line_num))
#      GC.start
#      print line_num, " "; $stdout.flush#":#{num_marks}:#{num_scopes} "; $stdout.flush
#      puts line_num
#       p line
#       puts @root.pretty
      check_line_exists(line_num)
      @scope_last_line = line_num if line_num > @scope_last_line
      if line_num == 0
        opening_scope = @root
      else
        opening_scope = (@ending_scopes[line_num-1] || @root)
      end
      @starting_scopes[line_num] = opening_scope
      last_child = if line_num > 0
                     @last_childs[line_num-1]
                   end
      lp = LineParser.new(self, line_num, line.to_s, opening_scope, last_child)

#       begin
        while lp.any_line_left?
          lp.scan_line
          if lp.any_markers?
            lp.process_marker
          else
            lp.clear_line
          end
        end
#       rescue Object => e
#         puts "[Red] error parsing line #{line_num}"
#         @ending_scopes[line_num] = lp.current_scope
#         return false
#       end

      if @colourer
       SyntaxExt.uncolour_scopes(@colourer, lp.removed_scopes)
        children_of_current = lp.all_scopes.select do |s|
          v = (s.parent == lp.current_scope)
        end
        if children_of_current.empty?
          if line_num > 0
            @last_childs[line_num] = @last_childs[line_num-1]
          end
        else
          @last_childs[line_num] = children_of_current.last.
            ancestral_child_of(lp.current_scope)
        end
        SyntaxExt.colour_line_with_scopes(@buf, @colourer.theme,
                                          lp.all_scopes)
      end

      # should we parse the next line? If we've changed the scope or the
      # next line has not yet been parsed.
      @ending_scopes[line_num] = lp.current_scope
      same = (@ending_scopes[line_num] == @starting_scopes[line_num+1] and
              @ending_scopes[line_num+1] != nil)
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
      @tags.each do |tag|
        @buf.remove_tag(tag, si, ei)
      end
    end

    def reset_table_priorities
#      p @tags.length
#      puts @tags.map{|t| t.name}
      tags = @tags.sort_by do |tag|
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
      attr_accessor(:start_scope, :active_grammar,
                    :all_scopes, :closed_scopes, :matching_patterns,
                    :need_new_patterns, :new_scope_markers, :removed_scopes  )
      attr_reader :current_child

      def initialize2(p, line, opening_scope, last_child_prev_line)
        @parser = p
        @start_scope = (opening_scope || p.scope_at_line_start(line_num))
        self.current_scope = @start_scope
        @active_grammar = p.grammar_for_scope(current_scope)
        @all_scopes = [current_scope]
        @closed_scopes = []
        @matching_patterns = []
        @line = line
        @need_new_patterns = true
        @new_scope_markers = []
        @removed_scopes = []
        @line_start_offset = @parser.buf.line_start(line_num).offset
        self.starting_child = last_child_prev_line
        reset_scope_marker
      end

      # use this method to compare ruby and C implementations.
      def self.c_diff(name, rbv, cv, data=nil)
        if rbv != cv
          puts "'#{name}' C version differs. rb: #{rbv.inspect}," +
            " c:#{cv.inspect}, data:#{data.inspect}"
        end
        rbv != cv
      end

      def dump_info
        File.open(Redcar::ROOT + "/parser_dump.txt", "w") do |f|
          f.puts "--- Parser Dump-------------"
          f.puts @parser.root.pretty
          f.puts "___Ending scopes______"
          @parser.ending_scopes.each do |sc|
            f.puts sc.inspect
          end
          f.puts "______________________"
        end
      end

      def any_line_left?
        pos <= line_length
      end

      def get_expected_scope
        expected_scope = current_scope.first_child_after(TextLoc.new(line_num, pos), starting_child)
        return nil if expected_scope == current_scope
        if expected_scope
          expected_scope = nil unless expected_scope.start.line == line_num
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

      def collect_captures(scope, type)
        case type
        when :end_captures
          matchdata_name = :close_matchdata
        when :begin_captures, :captures
          matchdata_name = :open_matchdata
        end
        if scope.pattern.respond_to? type
          sub_scopes = []
          scope.pattern.send(type).to_a.sort_by {|num, _| num}.each do |num, name|
            md = scope.send(matchdata_name)
            sc = scope_from_capture(line_num, num, md)
            if sc
              parent = find_enclosing_scope(sc, sub_scopes) || scope
              parent.add_child(sc, nil)
              already_child =  parent.children.find do |ac|
                ac.capture_num == num and ac.capture_end == type
              end
              if already_child
                parent.delete_child(already_child)
              end
              sc.name = name
              sc.grammar = active_grammar
              sc.capture = true
              closed_scopes << sc
              all_scopes << sc
              sc.capture_num = num
              sc.capture_end = type
              sub_scopes << sc
            end
          end
        end
      end

      def find_enclosing_scope(scope, scopes)
        start_line_offset = scope.start_line_offset
        end_line_offset = scope.end_line_offset
        scopes.select do |sc|
          sc.start_line_offset <= start_line_offset and
            sc.end_line_offset >= end_line_offset
        end.last
      end

      def scope_from_capture(line_num, num, md)
        num = num.to_i
        capture = get_capture(num, md)
        unless capture == ""
          from = md.begin(num)
          to   = md.end(num)
#           fromloc = ::Redcar::EditView::TextLoc.new(line_num, from)
#           toloc   = ::Redcar::EditView::TextLoc.new(line_num, to)
          fromoff = @line_start_offset + from
          tooff   = @line_start_offset + to
          sc = ::Redcar::EditView::Scope.create2
          sc.set_start_mark @parser.buf, fromoff, false
          sc.set_end_mark   @parser.buf, tooff,   true
          sc
        end
      end

      def get_capture(capture_index, md)
        if capture_index == 0
          md.to_s
        else
          md.captures[capture_index-1] || ""
        end
      end

      def close_current_scope(nsm)
        fromoff = @line_start_offset + nsm[:from]
        tooff   = @line_start_offset + nsm[:to]
        current_scope.set_end_mark       @parser.buf, tooff, true
        current_scope.set_inner_end_mark @parser.buf, fromoff, true
        current_scope.set_open(false)
        current_scope.close_matchdata = nsm[:md]
      end

      def new_single_scope(nsm)
        new_scope = nsm[:pattern].to_scope
        new_scope.grammar   = active_grammar
        fromoff = @line_start_offset + nsm[:from]
        tooff   = @line_start_offset + nsm[:to]
        new_scope.set_start_mark @parser.buf, fromoff, false
        new_scope.set_end_mark   @parser.buf, tooff, true
        new_scope.open_matchdata = nsm[:md]
        new_scope.name = nsm[:pattern].scope_name
        new_scope
      end

      def new_double_scope(nsm)
        pattern = nsm[:pattern]
        new_scope = pattern.to_scope
        new_scope.grammar = active_grammar

        fromoff = @line_start_offset + nsm[:from]
        tooff   = @line_start_offset + nsm[:to]
        new_scope.set_start_mark       @parser.buf, fromoff, false
        new_scope.set_inner_start_mark @parser.buf, tooff, false
        new_scope.set_inner_end_mark   @parser.buf, @parser.buf.char_count, false
        new_scope.set_end_mark         @parser.buf, @parser.buf.char_count, false
        new_scope.set_open(true)

        new_scope.open_matchdata = nsm[:md]
        re = Oniguruma::ORegexp.new(@parser.build_closing_regexp(pattern,
                                                                 nsm[:md]
                                                                 ),
                                    :options => Oniguruma::OPTION_CAPTURE_GROUP)
        new_scope.closing_regexp = re
        new_scope.name = pattern.scope_name
        new_scope
      end

      def remove_if_overlaps_with(expected_scope, new_scope)
        if new_scope.overlaps?(expected_scope) or
            new_scope.start > expected_scope.start
          current_scope.delete_child(expected_scope)
          @removed_scopes << expected_scope
        end
      end

      def remove_children_that_overlap_with(new_scope)
        arr = current_scope.remove_children_that_overlap(new_scope, starting_child)
        @removed_scopes += arr
      end

      def process_marker
        expected_scope = get_expected_scope
        new_scope_marker = get_scope_marker
        from = new_scope_marker[:from]
        md   = new_scope_marker[:md]
        to   = new_scope_marker[:to] = md.end(0)
        expected_scope = nil if expected_scope == current_scope
        case new_scope_marker[:pattern]
        when :close_scope
          if current_scope.end and
              current_scope.end == TextLoc.new(line_num, to) and
              current_scope.close_start == TextLoc.new(line_num, from) and
              current_scope.close_matchdata.to_s == md.to_s
            # we have already parsed this line and this scope ends here
            true
          else
            close_current_scope(new_scope_marker)
            collect_captures(current_scope, :end_captures)
            if expected_scope
              current_scope.delete_child(expected_scope)
              @removed_scopes << expected_scope
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
              current_scope.add_child(new_scope, starting_child)
            end
          else
            current_scope.add_child(new_scope, starting_child)
          end
          all_scopes << new_scope
          self.current_scope = new_scope
          need_new_patterns = true
        when SinglePattern
          new_scope = new_single_scope(new_scope_marker)

          if expected_scope
            if new_scope.surface_identical?(expected_scope)
              # don't need to do anything
              new_scope = expected_scope
              expected_scope.each_child {|c| closed_scopes << c}
            else
              collect_captures(new_scope, :captures)
              remove_if_overlaps_with(expected_scope, new_scope)
              current_scope.add_child(new_scope, starting_child)
            end
          else
            collect_captures(new_scope, :captures)
            current_scope.add_child(new_scope, starting_child)
          end
#          remove_children_that_overlap_with(new_scope)
          all_scopes << new_scope
          closed_scopes << new_scope
        end
        self.pos = new_scope_marker[:to]
#        puts @parser.root.pretty
      end

      def clear_line
#         p :clear_line
#         p line_num
#         p @line
#         puts @parser.root.pretty2
#         p @parser.ending_scopes
        if @parser.parsed_before?(line_num)
#           p all_scopes
          # If we are reparsing, we might find that some scopes have disappeared,
          # delete them:
#          arr = current_scope.root.delete_any_on_line_not_in(line_num, all_scopes, starting_child)
          arr = current_scope.root.delete_any_on_line_not_in(line_num,
                                                             all_scopes,
                                                             starting_child)
          @removed_scopes += arr

          # any that we expected to close on this line that now don't?
          #  first build list of scopes that close on this line (including ones
          #  that did but haven't been removed yet).
          scopes_that_closed_on_line = []
          ts = start_scope
          while ts.parent
            if ts.end and ts.end.line == line_num
              scopes_that_closed_on_line << ts
            end
            ts = ts.parent
          end
          scopes_that_closed_on_line.each do |s|
            unless closed_scopes.include? s
              if s.capture
                s.detach_from_parent
                @removed_scopes << s
              end
            end
          end
        end
        self.pos = line_length + 1
      end
    end

    def clear_after(line_num)
      @root.clear_after(TextLoc.new(line_num, 0))
      if line_num == 0
        @ending_scopes = []
        @starting_scopes = []
        @last_childs = []
        @scope_last_line = -1
      else
        @ending_scopes = @ending_scopes[0..(line_num-1)]
        @starting_scopes = @starting_scopes[0..(line_num-1)]
        @last_childs = @last_childs[0..(line_num-1)]
        @scope_last_line = line_num-1
      end
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

    def parsed_before?(line_num)
      @ending_scopes[line_num] and @starting_scopes[line_num]
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

  end
end
