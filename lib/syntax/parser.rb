
$spare_name = "aaaa"

module Redcar
  module Syntax
    class Parser
      attr_accessor :grammars, :lines, :scope_tree, :fold_counts, :text
      
      def initialize(opening_scope, grammars=[], text="")
        @text = []
        @scope_tree = opening_scope
        @fold_counts = []
        @ending_scopes = []
        @grammars = grammars
        add_lines(text) if text
      end
      
      def indent(line_num)
        if line_num == 0
          0
        else
          ind = 0
          prev = indent(line_num-1)
          if @fold_counts[line_num-1] > 0
            ind = prev + 1
          elsif @fold_counts[line_num-1] < 0
            ind = prev
          elsif @fold_counts[line_num-1] == 0
            ind = prev
          end
          if @fold_counts[line_num] < 0
            ind - 1
          else
            ind
          end
        end
      end
      
      def add_line(line)
        last_scope = @scope_tree.last_scope
        @text << line
        @fold_counts << 0
        @ending_scopes << nil
        parse_line(line, @text.length-1)
      end
      
      def delete_line(num)
        
        
#         before_scope = @scope_tree.scope_at(TextLoc.new(num, @text[num].length)) 
#         @text.delete_at(num)
#         @fold_counts.delete_at(num)
#         @scope_tree.clear_between(num, num)
#         @scope_tree.shift_after(num, -1)
#         after_scope  = @scope_tree.scope_at(TextLoc.new(num, @text[num].length))
#         debug_puts "before: #{before_scope.inspect}"
#         debug_puts "after:  #{after_scope.inspect}"
#         starts = @scope_tree.scope_beginning_on_line(num)
#         ends = @scope_tree.scopes_ending_on_line(num)
#         affected_from = affected_to = num
#         unless starts.empty?
#           affected_to = starts.map do |s|
#             if s.end
#               s.end.line
#             else
#               @text.length
#             end
#           end.max
#         end
#         unless ends.empty?
#           affected_from = starts.map {|s| s.start.line}.min
#         end
#         @scope_tree.clear_between(
#         affected_from.upto(affected_to) do |reparse_line|
          
#         end
#         until before_scope == after_scope
#           before_scope = @scope_tree.scope_at(TextLoc.new(num, @text[num].length)) 
#           parse_line(@text[num], num)
#           after_scope  = @scope_tree.scope_at(TextLoc.new(num, @text[num].length))
#         debug_puts "before: #{before_scope.inspect}"
#         debug_puts "after:  #{after_scope.inspect}"
#           num += 1
#         end
        
        before_scope = @scope_tree.scope_at(TextLoc.new(num-1, @text[num-1].length)) 
        after_scope  = @scope_tree.scope_at(TextLoc.new(num, @text[num].length))
        @text.delete_at(num)
        @fold_counts.delete_at(num)
        @scope_tree.clear_between(num, num)
        @scope_tree.shift_after(num, -1)
        debug_puts "before: #{before_scope.inspect}"
        debug_puts "after:  #{after_scope.inspect}"
        unless before_scope == after_scope
          # if we have deleted a scope opener:
          if after_scope.child_of? before_scope
            if after_scope.end
              affected_until = after_scope.end.line
            else
              affected_until = @text.length
            end
            @scope_tree.clear_between(num, affected_until)
            num.upto(affected_until) do |reparse_num|
              clear_line(reparse_num)
              parse_line(@text[reparse_num], reparse_num)
            end
          # else if we have deleted a scope closer
          elsif before_scope.child_of? after_scope
            ending_scope = before_scope
            until ending_scope == after_scope or num == @text.length
              debug_puts @scope_tree.pretty
              clear_line(num)
              parse_line(@text[num], num)
              ending_scope = @scope_tree.scope_at(TextLoc.new(num, @text[num].length))
              debug_puts "ending_scope:  #{ending_scope.inspect}"
              num += 1
            end
          end
        end
      end
      
      def insert_line(line, line_num)
        @text.insert(line_num, line)
        @fold_counts.insert(line_num, 0)
        @ending_scopes.insert(line_num, nil)
        shift_after(line_num, 1)
        parse_line(line, line_num)
        if (line_num > 0 and @ending_scopes[line_num] != @ending_scopes[line_num-1]) or
            (line_num == 0 and @ending_scopes[line_num] != @scope_tree)
          line_num += 1
          until line_num >= @text.length or parse_line(@text[line_num], line_num)
            debug_puts "not finished parsing"
            line_num += 1
          end
        end
      end
      
      def scope_at_end_of(num)
        @scope_tree.scope_at(TextLoc.new(num, @text[num].length))
      end
      
      def insert_in_line(line_num, text, offset)
        @text[line_num].insert(offset, text)
        @scope_tree.shift_chars(line_num, text.length, offset)
        until line_num >= @text.length or parse_line(@text[line_num], line_num)
          debug_puts "not finished parsing at end of #{line_num}"
          line_num += 1
        end
      end
      
      def delete_from_line(line_num, amount, offset)
        @text[line_num].delete_slice(offset..(offset+amount-1))
        @scope_tree.shift_chars(line_num, -amount, offset)
        until line_num >= @text.length or parse_line(@text[line_num], line_num)
          debug_puts "not finished parsing"
          line_num += 1
        end
      end
        
#         @text[line_num].insert(offset, text)
#         before_end_scope = @scope_tree.line_end(line_num)
        
#         # Create a target to compare against (model of
#         # situation where no scopes have changed).
#         target = @scope_tree.copy
#         target.clear_not_on_line(line_num)
#         target.shift_chars(line_num, text.length, offset)
        
#         # Reparse the line
#         @scope_tree.clear_between(line_num, line_num)
#         parse_line(@text[line_num], line_num)
#         after_end_scope = @scope_tree.line_end(line_num)
#         previous = @scope_tree.copy
#         @scope_tree.clear_not_on_line(line_num)
        
#         if target.identical?(@scope_tree)
#           # ... all the single scopes have just been bumped along
#           # and there were no open scopes so just save the target.
#           @scope_tree = previous
#         else
#           # ... there are differences, so merge the changes in.
          
#         end
#       end
      
      def add_lines(text)
        text.each do |line|
          add_line(line)
        end
        if text[-1..-1] == "\n" or text == ""
          add_line("")
        end
      end
      
      def parse_from(num)
        @scope_tree.clear_after(TextLoc.new(num, 0))
        (num).upto(@text.length-1) do |i|
        clear_line(line_num)
          parse_line(@text[i], i)
        end
      end

      def shift_after(line, amount)
        @scope_tree.shift_after(line, amount)
      end
      
      def clear_after(line_num)
        @scope_tree.clear_after(TextLoc.new(line_num, 0))
        if line_num == 0
          @text = []
          @fold_counts = []
        else
          @text = @text[0..line_num-1]
          @fold_counts[0..line_num-1]
        end
      end
      
      def clear_line(line)
        @scope_tree.clear_between(line, line)
      end
      
      def clear_between(line_from, line_to)
        @scope_tree.clear_between(line_from, line_to)
      end
      
      def scope_at(loc)
        @scope_tree.scope_at(loc)
      end
      
#       def find_all_fold_markers
#         @text.each_with_index do |line, i|
#           start_scope = scope_at(TextLoc.new(line_num, 0))
          
#         end
#       end
      
      def find_fold_marker(line, grammar)
        debug_puts "looking for fold_marker:"
        fline = line
        fold_count = 0
        md_start, md_stop = nil, nil
        md_start = fline.match(grammar.folding_start_marker) if grammar.folding_start_marker
        md_stop = fline.match(grammar.folding_stop_marker) if grammar.folding_stop_marker
        if md_start and md_stop
          if md_start.begin(0) < md_stop.begin(0)
            1
          elsif md_start.begin(0) > md_stop.begin(0)
            -1
          end
        elsif md_start
          1
        elsif md_stop
          -1
        else
          0
        end
      end
      
      def line_start(num)
        @scope_tree.line_start(num)
      end
      
      def line_end(num)
        @scope_tree.line_end(num)
      end
      
      # Parses line_num, using text line.
      def parse_line(line, line_num)
                debug_puts "parsing line #{line_num}"
        unless line_num <= @text.length-1 and line_num >= 0
          raise ArgumentError, "cannot parse line that does not exist"
        end
        
        start_scope = line_start(line_num)
        start_end_scope = line_end(line_num)
                debug_puts "start_scope:    #{start_scope.inspect}"
        
        if start_scope.respond_to? :grammar
          active_grammar = start_scope.grammar
        else
          active_grammar = grammar_for_scope(start_scope)
        end
        
        pos = 0
        current_scope = start_scope
        
        all_scopes = [current_scope]
        closed_scopes = []
        
        while pos < line.length
          rest_line = line[pos..-1]
                  debug_puts "rest of line: #{rest_line.inspect}"
                  debug_puts "  current_scope:     #{current_scope.inspect}"
          pps = active_grammar.possible_patterns(current_scope.pattern)
                  debug_puts "  possible patterns: "
                  debug_puts "    closing: " + Regexp.new(current_scope.closing_regexp).inspect if current_scope.closing_regexp
                  #pps.each {|p|     debug_puts "    " + p.inspect}
          new_scope_markers = []
                  debug_puts "  matches:"
          
          # See if the current scope is closed on this line.
          if current_scope.closing_regexp
                    debug_puts "  closing regexp: #{current_scope.closing_regexp}"
            if md = current_scope.closing_regexp.match(rest_line)
                      debug_puts "    matched closing regexp for #{current_scope.inspect}"
                      debug_puts "       match: \"#{md.to_s}\", captures: #{md.captures.inspect}"
              from = pos+md.begin(0)
              to   = pos+md.end(0)
                      debug_puts "       from: #{from}, to: #{to}"
              new_scope_markers << { :type => :close_scope, :from => from, 
                                     :to => to, :md => md }.picky
            end
          end
          
          # See if any scopes are opened on this line.
          pps.each do |pattern|
            case pattern
            when SinglePattern
              md = pattern.match.match(rest_line)
              if md
                        debug_puts "    matched SinglePattern: #{pattern.inspect}"
                        debug_puts "       match: \"#{md.to_s}\", captures: #{md.captures.inspect}"
                from = pos+md.begin(0)
                to   = pos+md.end(0)
                        debug_puts "       from: #{from}, to: #{to}"
                new_scope_markers << { :type => :single_scope, :from => from, 
                                       :to => to, :md => md, :pattern => pattern}.picky
              end
            when DoublePattern
              md = pattern.begin.match(rest_line)
              if md
                        debug_puts "    matched DoublePattern #{pattern.inspect}"
                        debug_puts "       match: \"#{md.to_s}\", captures: #{md.captures.inspect}"
                from = pos+md.begin(0)
                to   = pos+md.end(0)
                        debug_puts "       from: #{from}, to: #{to}"
                new_scope_markers << { :type => :open_scope, :from => from, 
                                       :to => to, :pattern => pattern, :md => md}.picky
              end
            end
          end
          
          expected_scope = current_scope.first_child_after(TextLoc.new(line_num, pos))
          debug_puts "  expected_scope: #{expected_scope.inspect}"
          if new_scope_markers.length > 0
            new_scope_marker = new_scope_markers.sort_by {|sm| sm; sm[:from] }[0]
                    debug_puts "  first_new_scope: #{new_scope_marker.inspect}"
            from = new_scope_marker[:from]
            to   = new_scope_marker[:to]
            md   = new_scope_marker[:md]
            
            case new_scope_marker[:type]
            when :close_scope
              if current_scope.end and 
                  current_scope.end == TextLoc.new(line_num, to) and
                  current_scope.close_start == TextLoc.new(line_num, from) and
                  current_scope.close_end   == TextLoc.new(line_num, to) and
                  current_scope.close_matchdata.to_s == md.to_s
                # we have already parsed this line and this scope ends here
                debug_puts "closes as expected"
                true
              else
                current_scope.end         = TextLoc.new(line_num, to)
                current_scope.close_start = TextLoc.new(line_num, from)
                current_scope.close_end   = TextLoc.new(line_num, to)
                current_scope.close_matchdata = md
                if current_scope.pattern.respond_to? :end_captures
                  current_scope.pattern.end_captures.each do |num, name|
                    md = current_scope.close_matchdata
                    sc = scope_from_capture(line_num, pos, num, md)
                    if sc
                      current_scope.add_child(sc)
                      sc.parent = current_scope
                      sc.name = name
                      sc.grammar = active_grammar
                      closed_scopes << sc
                    end
                  end
                end
              end
              closed_scopes << current_scope
              current_scope = current_scope.parent
            when :open_scope
              pattern = new_scope_marker[:pattern]
              new_scope = pattern.to_scope
              new_scope.grammar = active_grammar
              new_scope.parent  = current_scope
              new_scope.start   = TextLoc.new(line_num, from)
              new_scope.end     = nil
              new_scope.open_start = TextLoc.new(line_num, from)
              new_scope.open_end   = TextLoc.new(line_num, to)
              new_scope.open_matchdata = md
              new_scope.closing_regexp = Regexp.new(build_closing_regexp(pattern, md))
              
              if new_scope.pattern.respond_to? :begin_captures
                debug_puts new_scope.pattern.begin_captures.inspect
                new_scope.pattern.begin_captures.each do |num, name|
                  debug_puts "  child capture: #{num}-#{name}"
                  md = new_scope.open_matchdata
                  sc = scope_from_capture(line_num, pos, num, md)
                  if sc
                    new_scope.add_child(sc)
                    sc.parent = new_scope
                    sc.name = name
                    sc.grammar = active_grammar
                    closed_scopes << sc
                  end
                end
              end
              
              if expected_scope
                # check mod ending scopes as the new one will not have a closing marker
                # but the expected one will:
                if new_scope.surface_identical_modulo_ending?(expected_scope)
                  debug_puts "  identical to expected scope"
                  # don't need to do anything as we have already found this,
                  # but let's keep the old scope since it will have children and what not.
                  new_scope = expected_scope
                  expected_scope.children.each {|c| closed_scopes << c}
                else
                  debug_puts "  not as expected:"
                  debug_puts "    #{new_scope.inspect}\n    #{expected_scope.inspect}"
                  if new_scope.overlaps?(expected_scope)
                    current_scope.children.delete(expected_scope)
                  end
                  current_scope.add_child(new_scope)
                end
              else
                current_scope.add_child(new_scope)
              end
              all_scopes << new_scope
              current_scope = new_scope
            when :single_scope
              new_scope = new_scope_marker[:pattern].to_scope
              new_scope.grammar = active_grammar
              new_scope.parent  = current_scope
              new_scope.start   = TextLoc.new(line_num, from)
              new_scope.end     = TextLoc.new(line_num, to)
              new_scope.open_start = TextLoc.new(line_num, from)
              new_scope.open_end   = TextLoc.new(line_num, to)
              new_scope.open_matchdata = md
              new_scope.parent = current_scope
              if new_scope.pattern.respond_to? :captures
                        debug_puts "  children:"
                new_scope.pattern.captures.each do |num, name|
                          debug_puts "    (#{num}) #{name}:"
                  md = new_scope.open_matchdata
                  sc = scope_from_capture(line_num, pos, num, md)
                  if sc
                    new_scope.add_child(sc)
                    sc.parent = new_scope
                    sc.name = name
                    sc.grammar = active_grammar
                    closed_scopes << sc
                  end
                end
              end
              
              if expected_scope
                if new_scope.surface_identical?(expected_scope)
                  debug_puts "identical to expected scope"
                  # don't need to do anything
                  new_scope = expected_scope
                  expected_scope.children.each {|c| closed_scopes << c}
                else  
                  debug_puts "not as expected"
                  if new_scope.overlaps?(expected_scope)
                    current_scope.children.delete(expected_scope)
                  end
                  current_scope.add_child(new_scope)
                end
              else
                current_scope.add_child(new_scope)
              end
              all_scopes << new_scope
              closed_scopes << new_scope
            end
            pos = new_scope_marker[:to]
          else
                    debug_puts "  no matches"
#             # If we are reparsing, we might find that some scopes have disappeared,
#             # delete them:
#             while unwanted = current_scope.first_child_after(TextLoc.new(line_num, pos)) and 
#                 unwanted.start.line == line_num
#               debug_puts "deleting: #{unwanted.inspect}"
#               current_scope.children.delete(unwanted)
#               pos = unwanted.open_end.offset
#             end
            @scope_tree.delete_any_on_line_not_in(line_num, all_scopes)
            
            # any that we expected to close on this line that now don't?
            @scope_tree.scopes_closed_on_line(line_num) do |s|
              unless closed_scopes.include? s
                debug_puts "scope closes on line and should be deleted: #{s.inspect}"
                s.detach_from_parent
              end
            end
            pos = line.length + 1
          end
        end
        same = (@ending_scopes[line_num] == current_scope)
        @ending_scopes[line_num] = current_scope
        same
      end
      
      def scope_from_capture(line_num, pos, num, md)
        capture = get_capture(num, md)
        unless capture.blank?
          from = pos + md.begin(num.to_i)
          to   = pos + md.end(num.to_i)
                  debug_puts "      #{capture} #{from}-#{to}"
          Scope.new(:start => TextLoc.new(line_num, from),
                    :end   => TextLoc.new(line_num, to))
        end
      end
      
      def grammar_for_scope(scope_name)
        @grammars.find do |gr|
          gr.scope_name == scope_name
        end
      end
      
      def build_closing_regexp(pattern, md)
        new_end = pattern.end.gsub(/\\([0-9]+)/) do
          #        debug_puts "replace with: #{md.captures.send(:[], $1.to_i-1)}"
          md.captures.send(:[], $1.to_i-1)
        end
      end

      def get_capture(str, md)
        capture_index = str.to_i-1
        if capture_index == -1
          capture = md.to_s
        else
          tmp = md.captures.map{|c| (c==nil ? "" : c)}
          capture = tmp[capture_index]
        end
        if capture == nil
          p md
          p md.to_s
          p md.captures
          p capture_index
          raise StandardError, "capture not found"
        end
        capture
      end
    end
  end
end
