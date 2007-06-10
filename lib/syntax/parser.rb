
$spare_name = "aaaa"

class RedcarSyntaxError < StandardError; end

module Redcar
  module Syntax
    class Parser
      include DebugPrinter
      
      attr_accessor :grammars, :lines, :scope_tree, :fold_counts, :text, :colourer
      
      def initialize(opening_scope, grammars=[], text="", colourer=nil)
        @text = []
        @scope_tree = opening_scope
        @fold_counts = []
        @ending_scopes = []
        @grammars = grammars
        @colourer = colourer
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
      
      def add_lines(text, options=nil)
        curr_last = @text.length-1
        text.each do |line|
          add_line_info(line)
        end
        if text[-1..-1] == "\n" or text == ""
          add_line_info("")
        end
        lazy_parse_from(curr_last+1, options)
      end
      
      def add_line_info(line)
        @text << line
        @fold_counts << 0
        @ending_scopes << nil
      end
      
      def add_line(line)
        add_line_info(line)
        parse_line(line, @text.length-1)
      end
      
      def lazy_parse_from(line_num, options=nil)
        debug_puts {@scope_tree.pretty}
        count = 0
        ok = true
        debug_puts {"lazy_parse: parsing five: #{line_num} (#{@text.length}), #{count}, #{ok}"}
        until line_num >= @text.length or 
            count >= 100 or 
            ok = parse_line(@text[line_num], line_num)
          debug_puts {"lazy_parse: not done: #{line_num} (#{@text.length}), #{count}, #{ok}"}
          line_num += 1
          count += 1
        end
        unless ok or line_num >= @text.length
          debug_puts {"lazy parsing line: #{line_num}"}
          if (!options or options[:lazy]) #and
          #    !$REDCAR_ENV["nonlazy"]
            Gtk.idle_add_priority(GLib::PRIORITY_LOW) do
              lazy_parse_from(line_num, options)
              false
            end
          else
            lazy_parse_from(line_num, options)
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
          lazy_parse_from(line_num)
        end
      end
      
      def string_to_lines(text)
        lines = text.split("\n")
        lines << "" if text[-1..-1] == "\n"
        lines << "" if text == "\n"
        lines
      end
    
      def insert(loc, text)
        unless text.include?("\n")
          insert_in_line(loc.line, text, loc.offset)
        else
          lines = string_to_lines(text)
          # end of first inserted line
          before = @text[loc.line][0..(loc.offset-1)]
          after  = @text[loc.line][(loc.offset)..-1]
          after_scope = line_end(loc.line)
          unless loc.offset == @text[loc.line].length
            @text[loc.line].delete_slice((loc.offset)..-1)
          end
          @text[loc.line] << lines[0]+"\n"
          @text.insert(loc.line+1, after)
          # middle lines
          lines[1..-2].each_with_index do |line, i|
            @text.insert(loc.line+i+1, line+"\n")
          end
          # start of last inserted_line
          @text[loc.line+lines.length-1].insert(0, lines.last)
          
          @scope_tree.shift_after(loc.line+1, lines.length-1)
          
          line_num = loc.line
          debug_puts {"parsing new lines"}
          lines.length.times do |i|
            parse_line(@text[line_num], line_num)
            line_num += 1
          end
          new_after_scope = line_end(loc.line+lines.length)
          unless new_after_scope == after_scope
            debug_puts {"have some reparsing to do"}
            lazy_parse_from(line_num)
          end
        end
      end
      
      def scope_at_end_of(num)
        @scope_tree.scope_at(TextLoc.new(num, @text[num].length))
      end
      
      def insert_in_line(line_num, text, offset)
        if @text[line_num]
          @text[line_num].insert(offset, text)
          @scope_tree.shift_chars(line_num, text.length, offset)
          lazy_parse_from(line_num)
        else
          raise RedcarSyntaxError, "RedcarSyntaxError: trying to insert text in line that"+
            "doesn't exist (#{line_num})"
        end
      end
      
      def delete_between(from, to)
        if from.line == to.line
          delete_from_line(from.line, to.offset-from.offset, from.offset)
        else
          debug_puts "multiple line deletion"
          # end of first line
          @text[from.line].delete_slice(from.offset..-1)
          # all of middle lines
          (to.line-from.line-1).times do |i|
            @text.delete_at(from.line+1)
          end
          # start of last line
          @text[from.line] << @text[from.line+1][to.offset..-1]
          @text.delete_at(from.line+1)
          
          @scope_tree.clear_between_lines(from.line+1, to.line)
          @scope_tree.shift_after(from.line+1, -(to.line-from.line))
          
          line_num = from.line
          lazy_parse_from(line_num)
        end
      end
      
      def delete_from_line(line_num, amount, offset)
        if @text[line_num]
          @text[line_num].delete_slice(offset..(offset+amount-1))
          @scope_tree.shift_chars(line_num, -amount, offset)
          lazy_parse_from(line_num)
        else
          raise RedcarSyntaxError, "RedcarSyntaxError: trying to delete text from line that"+
            "doesn't exist (#{line_num})"
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
          @ending_scopes = []
        else
          @text = @text[0..(line_num-1)]
          @fold_counts = @fold_counts[0..(line_num-1)]
          @ending_scopes = @ending_scopes[0..(line_num-1)]
        end
      end
      
      def clear_line(line)
        @scope_tree.clear_between_lines(line, line)
      end
      
      def clear_between_lines(line_from, line_to)
        @scope_tree.clear_between_lines(line_from, line_to)
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
        debug_puts {"parsing line #{line_num}"}
        unless line_num <= @text.length-1 and line_num >= 0
          raise ArgumentError, "cannot parse line that does not exist"
        end
        
        current_scope = line_start(line_num)
        debug_puts {"current_scope:    #{current_scope.inspect}"}
        
        if current_scope.respond_to? :grammar
          active_grammar = current_scope.grammar
        else
          active_grammar = grammar_for_scope(current_scope)
        end
        
        pos = 0
        all_scopes = [current_scope]
        closed_scopes = []
         
        matching_patterns = nil
        count2 = 0
        while pos < line.length
          count2 += 1
          rest_line = line[pos..-1]
          new_scope_markers = []
          debug_puts {"rest of line: #{rest_line.inspect}"}
          debug_puts {"  current_scope:     #{current_scope.inspect}"}
          pps ||= current_scope.pattern.possible_patterns
          debug_puts "  possible patterns: "
          #if current_scope.closing_regexp
          #  debug_puts { "    closing: " + 
          #    Regexp.new(current_scope.closing_regexp).inspect
          #  } 
          #end
                  #pps.each {|p|     debug_puts "    " + p.inspect}
          debug_puts {"  matches:"}
          
          # See if the current scope is closed on this line.
          if current_scope.closing_regexp
#             if new_scope_markers.select{|sm| sm[:type] == :close_scope}.empty?
              debug_puts {"  closing regexp: #{current_scope.closing_regexp}"}
              if md = current_scope.closing_regexp.match(rest_line)
                debug_puts {"    matched closing regexp for #{current_scope.inspect}"}
                debug_puts {"       match: \"#{md.to_s}\", captures: #{md.captures.inspect}"}
                from = md.begin(0)
                debug_puts {"       from: #{from}, to: #{md.end(0)}"}
                new_scope_markers << { :from => from, :md => md, :pattern => :close_scope }
              end
#             end
          end
          
          # See if any scopes are opened on this line.
          Instrument("possible_patterns_#{active_grammar.name}".intern, pps.length)
          #count = 0
          if matching_patterns == nil
            recording_patterns = true
            possible_patterns = pps
            matching_patterns = []
          else
            recording_patterns = false
            possible_patterns = matching_patterns
            Instrument("matching_patterns_#{active_grammar.name}".intern, matching_patterns.length)
          end
          possible_patterns.each do |pattern|
            md = nil
#             old_patterns = new_scope_markers.map do |sm|
#               if sm[:type] == :single_scope or 
#                   sm[:type] == :double_scope
#                 sm[:pattern]
#               else
#                 nil
#               end
#             end.compact
#             unless old_patterns.include? pattern
              #count += 1
              md = pattern.match.match(rest_line)
              if md
                debug_puts {"    matched SinglePattern: #{pattern.inspect}"}
                debug_puts {"       match: \"#{md.to_s}\", captures: #{md.captures.inspect}"}
                from = md.begin(0)
                debug_puts {"       from: #{from}, to: #{md.end(0)}"}
                new_scope_markers << { :from => from, :md => md, :pattern => pattern }
                matching_patterns << pattern if recording_patterns
              end
#             end
#             if !recording_patterns and md and (md.begin(0) == 0 or 
#                        (rest_line[0..(md.begin(0)-1)] =~ /^\s*$/))
#               pattern.hint = pattern.hint + 1
#               break
#             end
          end
          #Instrument("possible_patterns_checked_#{active_grammar.name}".intern, count)
#           count = 0
#           froms = new_scope_markers.map {|sm| sm[:from]}
#           froms.each do |i|
#             if froms.select{|v| v==i}.length > 1
#               count += 1
#             end
#           end
#           Instrument("duplicate_starts_#{active_grammar.name}".intern, count)
          
          if parsed_before?(line_num)
            expected_scope = current_scope.first_child_after(TextLoc.new(line_num, pos))
          end
          
          if expected_scope
            expected_scope = nil unless expected_scope.start.line == line_num
          end
          debug_puts {"  expected_scope: #{expected_scope.inspect}"}
          if new_scope_markers.length > 0
            new_scope_marker = new_scope_markers.sort_by {|sm| sm; sm[:from] }[0]
            from = new_scope_marker[:from]
            pre = new_scope_marker
            new_scope_marker = new_scope_markers.select do |sm|
              sm[:from] == from
            end.sort_by do |sm|
              if sm[:pattern] == :close_scope
                0
              else
                # The hint tells the parser to tie-break matches
                # by which came first. 
                sm[:pattern].hint
              end
            end.first
#             if new_scope_marker != pre
#               puts
#               p new_scope_marker
#               p pre
#             end
            
            debug_puts {"  first_new_scope: #{new_scope_marker.inspect}"}
            new_scope_marker[:from] += pos
            from += pos
            md   = new_scope_marker[:md]
            to   = new_scope_marker[:to] = pos+md.end(0)
            
            case new_scope_marker[:pattern]
            when :close_scope
              if current_scope.end and 
                  current_scope.end == TextLoc.new(line_num, to) and
                  current_scope.close_start == TextLoc.new(line_num, from) and
                  current_scope.close_end   == TextLoc.new(line_num, to) and
                  current_scope.close_matchdata.to_s == md.to_s
                # we have already parsed this line and this scope ends here
                debug_puts {"closes as expected"}
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
                if expected_scope
                  debug_puts "deleting expected scope"
                  current_scope.children.delete(expected_scope)
                end
              end
              closed_scopes << current_scope
              current_scope = current_scope.parent
              pps = nil
#               new_scope_markers = []
              matching_patterns = nil
            when DoublePattern
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
                debug_puts {new_scope.pattern.begin_captures.inspect}
                new_scope.pattern.begin_captures.each do |num, name|
                  debug_puts {"  child capture: #{num}-#{name}"}
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
                  debug_puts {"  identical to expected scope"}
                  # don't need to do anything as we have already found this,
                  # but let's keep the old scope since it will have children and what not.
                  new_scope = expected_scope
                  expected_scope.children.each {|c| closed_scopes << c}
                else
                  debug_puts "  not as expected:"
                  debug_puts {"    #{new_scope.inspect}\n    #{expected_scope.inspect}"}
                  if new_scope.overlaps?(expected_scope) or
                      new_scope.start > expected_scope.start
                    debug_puts "  so deleting expected scope: #{expected_scope}"
                    current_scope.children.delete(expected_scope)
                  end
                  current_scope.add_child(new_scope)
                end
              else
                current_scope.add_child(new_scope)
              end
              all_scopes << new_scope
              current_scope = new_scope
#               new_scope_markers = []
              matching_patterns = nil
              pps = nil
            when SinglePattern
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
                  debug_puts { "    (#{num}) #{name}:" }
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
                  debug_puts {"    #{new_scope.inspect}\n    #{expected_scope.inspect}"}
                  if new_scope.overlaps?(expected_scope) or
                      new_scope.start > expected_scope.start
                    debug_puts "  so deleting expected scope: #{expected_scope.inspect}"
                    current_scope.children.delete(expected_scope)
                    debug_puts "  current_scope.children: #{current_scope.children.inspect}"
                  end
                  current_scope.add_child(new_scope)
                end
              else
                current_scope.add_child(new_scope)
              end
              current_scope.children.each do |child|
                if child.overlaps?(new_scope) and 
                    child != new_scope
                   debug_puts "deleting: #{child.inspect}"
                  current_scope.children.delete(child)
                end
              end
              all_scopes << new_scope
              closed_scopes << new_scope
#               new_scope_markers.delete new_scope_marker
#               new_scope_markers.reject! do |sm|
#                 sm[:to] and sm[:to] <= new_scope_marker[:to]
#               end
            end
            pos = new_scope_marker[:to]
          else
                    debug_puts "  no matches"
            if parsed_before?(line_num)
              # If we are reparsing, we might find that some scopes have disappeared,
              # delete them:
              @scope_tree.delete_any_on_line_not_in(line_num, all_scopes)
              
              # any that we expected to close on this line that now don't?
              @scope_tree.scopes_closed_on_line(line_num) do |s|
                unless closed_scopes.include? s
                  debug_puts {"scope closes on line and should be deleted: #{s.inspect}"}
                  s.detach_from_parent
                end
              end
            end
            pos = line.length + 1
          end
        end
        Instrument("line_repeats_#{active_grammar.name}".intern, count2)
        if @colourer
          debug_puts {"calling colourer"}
          @colourer.colour_line(@scope_tree, line_num)
        else
          debug_puts {"no colourer"}
        end
        # should we parse the next line? If we've changed the scope or the 
        # next line has not yet been parsed.
        same = ((@ending_scopes[line_num] == current_scope) and @ending_scopes[line_num+1] != nil)
        @ending_scopes[line_num] = current_scope
        same
      end
      
      def parsed_before?(line_num)
        @ending_scopes[line_num]
      end
      
      def scope_from_capture(line_num, pos, num, md)
        num = num.to_i
        capture = get_capture(num, md)
        unless capture == ""
          from = pos + md.begin(num)
          to   = pos + md.end(num)
          debug_puts {"      #{capture} #{from}-#{to}"}
          Scope.create2(TextLoc.new(line_num, from), TextLoc.new(line_num, to))
#           Scope.new(:start => TextLoc.new(line_num, from),
#                     :end   => TextLoc.new(line_num, to))
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

      def get_capture(capture_index, md)
        if capture_index == 0
          md.to_s
        else
          md.captures[capture_index-1] || ""
        end
      end
    end
  end
end
