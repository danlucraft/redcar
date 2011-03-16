
module Redcar
  class Snippets

    class DocumentController
      include Redcar::Document::Controller
      include Redcar::Document::Controller::ModificationCallbacks
      include Redcar::Document::Controller::CursorCallbacks

      attr_reader :current_snippet, :mirrors

      def before_modify(start_offset, end_offset, text)
        if in_snippet?
          @start_offset = start_offset
          @end_offset   = end_offset
          @text         = text
        end
      end

      def after_modify
        if in_snippet? and @start_offset and !@constructing
          left_marks = marks_at_offset(@start_offset)
          right_marks = marks_at_offset(@start_offset + @text.length)
          if @editing_stop_id
            current_stop_id = @editing_stop_id
          else
            left_tab_stops = left_marks.select {|m| m.name =~ /^\$/ }.map(&:stop_id)
            right_tab_stops = right_marks.select {|m| m.name =~ /^\$/ }.map(&:stop_id)
            current_stop_id = (left_tab_stops + right_tab_stops).sort.first
          end
          current_left_mark = left_marks.find {|m| m.stop_id == current_stop_id }
          current_right_mark = right_marks.find {|m| m.stop_id == current_stop_id }
          if current_left_mark
            current_left_offset = current_left_mark.mark.get_offset
            (left_marks + right_marks).each do |mark|
              if mark.stop_id != current_stop_id
                if mark.order_id < current_left_mark.order_id and
                    mark.mark.get_offset > current_left_offset
                  mark.mark.location.offset = current_left_mark.mark.get_offset
                end
              end
            end
          end
          if current_right_mark
            current_right_offset = current_right_mark.mark.get_offset
            (left_marks + right_marks).each do |mark|
              if mark.stop_id != current_stop_id
                if mark.order_id > current_right_mark.order_id and
                    mark.mark.get_offset < current_right_offset
                  mark.mark.location.offset = current_right_mark.mark.get_offset
                end
              end
            end
          end
        end
        if in_snippet?
          if @end_offset
            if @end_offset > @start_offset and !@ignore
              update_after_delete(@start_offset, @end_offset)
            end
            if !@ignore and @start_offset
              document.controllers(AutoPairer::DocumentController).first.ignore do
                update_after_insert(@start_offset, @text.length)
              end
              @start_offset, @end_offset, @text = nil, nil, nil
            end
          else
            clear_snippet
          end
        end

        false
      end

      def cursor_moved(new_offset)
        if @current_snippet and !@ignore
          check_in_snippet
        end
      end

      def start_snippet!(snippet)
        @current_snippet = snippet
        document.controllers(AutoPairer::DocumentController).first.ignore do
          document.edit_view.delay_parsing do
            insert_snippet(snippet)
          end
        end
      end

      def in_snippet?
        !!current_snippet
      end

      SnippetMark ||= Struct.new(:mark, :order_id, :stop_id)

      class SnippetMark
        attr_accessor :name
      end

      def insert_snippet(snippet)
        @content = snippet.content
        @insert_line_num = document.cursor_line
        @tab_stops = {}
        @mirrors = {}
        @transformations = {}
        @ignore = true
        @constructing = true
        @marks = []
        @order_id = 0
        @stop_id = 0

        @env = Textmate::Environment.new
        fix_line_endings
        # Not sure what to do about backticks. Currently they don't work in Redcar.
        #@content = execute_backticks(@content, bundle ? bundle.dir : nil)
        selection_range = document.selection_range
        document.delete(selection_range.begin, selection_range.count)
        parse_text_for_tab_stops(@content)
        unless @tab_stops.include? 0
          @snippet_end_mark = document.create_mark(document.cursor_offset, :right)
        end
        fix_indent
        create_right_marks
        @constructing = false
        set_names
        insert_duplicate_contents
        @ignore = false
        if @tab_stops.keys.include? 1
          select_tab_stop(1)
        elsif !@tab_stops.empty?
          select_tab_stop(@tab_stops.keys.sort.first)
        end
      end

      def leading_whitespace(line)
        line[/^(\s*)([^\s]|$)/, 1].chomp
      end

      def fix_line_endings
        if document.delim != "\n" # textmate uses "\n" everywhere
          @content = @content.gsub("\n", document.delim)
        end
      end

      def compute_tab_stop(line, tab_width, soft_tabs)
        re = / {0,#{tab_width - 1}}\t|#{" "*tab_width}/
        sc = StringScanner.new(leading_whitespace(line))
        tab_stop = 0
        tab_stop += 1 while sc.skip(re)
        tab_stop
      end

      def fix_indent
        tab_width = document.edit_view.tab_width
        soft_tabs  = document.edit_view.soft_tabs?
        line = document.get_line(@insert_line_num)
        tab_stop = compute_tab_stop(line, tab_width, soft_tabs)
        (@insert_line_num + 1).upto(@end_line_num) do |line_ix|
          this_line = document.get_line(line_ix)
          this_tab_stop = compute_tab_stop(this_line, tab_width, soft_tabs)
          new_tab_stop  = tab_stop + this_tab_stop
          pre = leading_whitespace(this_line)
          if soft_tabs
            new_indent = " "*tab_width*new_tab_stop
          else
            new_indent = "\t"*new_tab_stop
          end
          document.insert(document.offset_at_line(line_ix), new_indent)
          document.delete(document.offset_at_line(line_ix) + new_indent.length, pre.length)
        end
      end

      def unescape(text)
        text.gsub("\\$", "$").gsub("\\\\", "\\").gsub("\\}", "}").gsub("\\`", "`")
      end

      def insert_at_cursor_with_gravity(text)
        document.insert_at_cursor(text)
        document.cursor_offset += text.length
      end

      def check_in_snippet
        clear_snippet unless find_current_tab_stop
      end

      def parse_text_for_tab_stops(text)
  #       puts "parse_text_for_tab_stops(#{text.inspect})"
        remaining_content = text
        i = 0
        while remaining_content.length > 0
          i += 1
          raise "Snippet failed to parse: #{text.inspect}" if i > 100

          if md = Regexp.new("(?<!\\\\)\\$").match(remaining_content)
            insert_at_cursor_with_gravity(unescape(md.pre_match))
            @stop_id += 1
            if md1 = md.post_match.match(/\A(\d+)/) or md1 = md.post_match.match(/\A\{(\d+)\}/)
              remaining_content = md1.post_match
              # Simple tab stop "... $1 ... " or " ... ${1} ..."
              if !@tab_stops.include? $1.to_i
                @tab_stops[$1.to_i] = {
                  :leftmark => create_mark_at_offset(@stop_id, @order_id+=1, document.cursor_offset),
                  :rightmark => create_mark_at_offset(@stop_id, @order_id+=1, document.cursor_offset),
                  :order_id => @order_id,
                  :stop_id => @stop_id
                }
              else
                # it's a mirror
                @mirrors[$1.to_i] ||= []
                @mirrors[$1.to_i] << {
                  :leftmark => create_mark_at_offset(@stop_id, @order_id+=1, document.cursor_offset),
                  :rightmark => create_mark_at_offset(@stop_id, @order_id+=1, document.cursor_offset),
                  :order_id => @order_id,
                  :stop_id => @stop_id
                }
              end
            elsif md1 = md.post_match.match(/\A((\w+|_)+)\b/)
              insert_at_cursor_with_gravity(@env[$1]||"")
              # it is an environment variable " ... $TM_LINE_NUMBER ... "
              remaining_content = md1.post_match
            elsif md1 = md.post_match.match(/\A\{/)
              # tab stop with placeholder string "... ${1:condition ... "
              # puts "md.post_match = #{md.post_match.inspect}"
              balanced_braces = get_balanced_braces(md.post_match)
              # puts "balanced_braces: #{balanced_braces.inspect}"
              defn = balanced_braces[2..-2]
              if md2 = defn.match(/\A(\d+):/)
                # placeholder is a string
                stop_id = @stop_id
                left = create_mark_at_offset(stop_id, @order_id+=1, document.cursor_offset)
                parse_text_for_tab_stops(md2.post_match)
                if !@tab_stops.include? md2[1].to_i
                  @tab_stops[md2[1].to_i] = {
                    :leftmark => left,
                    :rightmark => create_mark_at_offset(stop_id, @order_id+=1, document.cursor_offset),
                    :order_id => @order_id,
                    :stop_id => @stop_id
                  }
                else
                  # it's a mirror
                  @mirrors[md2[1].to_i] ||= []
                  @mirrors[md2[1].to_i] << {
                    :leftmark => left,
                    :rightmark => create_mark_at_offset(stop_id, @order_id+=1, document.cursor_offset),
                    :order_id => @order_id,
                    :stop_id => @stop_id
                  }
                end
                remaining_content = md1.post_match[(defn.length+1)..-1]
              elsif md2 = defn.match(/\A(\d+)\//)
                # placeholder is a transformation
                bits = onig_split(defn, Regexp.new("(?<!\\\\)/"))
                bits[2] = bits[2].gsub("\\/", "/")
                @transformations[md2[1].to_i] ||= []
                @transformations[md2[1].to_i] << {
                  :leftmark => create_mark_at_offset(@stop_id, @order_id+=1, document.cursor_offset),
                  :rightmark => create_mark_at_offset(@stop_id, @order_id+=1, document.cursor_offset),
                  :replace => RegexReplace.new(bits[1], bits[2]),
                  :global => bits[3] == "g" ? true : false,
                  :order_id => @order_id,
                  :stop_id => @stop_id
                }
                remaining_content = md1.post_match[(defn.length+1)..-1]
              elsif md2 = defn.match(/\A((\w+|_)+)$/)
                # naked environment variable
                insert_at_cursor_with_gravity(@env[$1]||"")
                remaining_content = md1.post_match[(defn.length+1)..-1]
              elsif md2 = defn.match(/\A((\w+|_)+)\//)
                # transformed env variable
                env = @env[$1]||""
                bits = onig_split(md2.post_match, Regexp.new("(?<!\\\\)/"))
                bits[1] = bits[1].gsub("\\/", "/")
                rr = RegexReplace.new(bits[0], bits[1])
                if bits[2] == "g"
                  tenv = rr.grep(env)
                else
                  tenv = rr.rep(env)
                end
                insert_at_cursor_with_gravity(tenv)
                remaining_content = md1.post_match[(defn.length+1)..-1]
              elsif md2 = defn.match(/\A((\w+|_)+):/)
                # env variable with default e.g. ${TM_SELECTED_TEXT:Banner}
                default = md2.post_match
                env = @env[$1] || default
                insert_at_cursor_with_gravity(env)
                remaining_content = md1.post_match[(defn.length+1)..-1]
              else
                puts "unknown type of tab stop: #{defn.inspect}"
                remaining_content = md1.post_match[(defn.length+1)..-1]
              end
            end
          else
            insert_at_cursor_with_gravity(unescape(remaining_content))
            remaining_content = ""
          end
        end
        @end_line_num = document.cursor_line
      end

      def onig_split(string, re)
        line = string.dup
        bits = []
        while line.length > 0 and
            md = re.match(line)
          line = md.post_match
          bits << md.pre_match
        end
        bits << line
        bits
      end

      def create_right_marks
        hashes = []
        @tab_stops.each {|_, h| hashes << h}
        @mirrors.each {|_, hs| hs.each {|h| hashes << h}}
        @transformations.each {|_, hs| hs.each {|h| hashes << h}}
        hashes.each do |hash|
          if right = hash[:rightmark]
            new_right_mark = document.create_mark(right.mark.get_offset, :right)
            new_right = SnippetMark.new(new_right_mark, right.order_id, right.stop_id)
            hash[:rightmark] = new_right
            document.delete_mark(right.mark)
            @marks.delete(right)
          else
            raise "error: no rightmark already here"
          end
          @marks << new_right
        end
      end

      def create_mark_at_offset(stop_id, order_id, offset)
        mark = document.create_mark(offset, :left)
        snippet_mark = SnippetMark.new(mark, order_id, stop_id)
        @marks << snippet_mark
        snippet_mark
      end

      def marks_at_cursor
        marks_at_offset(document.cursor_offset)
      end

      def marks_at_offset(offset)
        marks.select {|m| m.mark.get_offset == offset }
      end

      def marks
        @marks
      end

      def update_after_insert(offset, length)
        #@buf.parser.stop_parsing
        update_mirrors(offset, offset+length)
        update_transformations(offset, offset+length)
        #@buf.parser.start_parsing
      end

      def update_after_delete(offset1, offset2)
        #@buf.parser.stop_parsing
        delete_any_mirrors(offset1, offset2)
        update_mirrors(offset1, offset2)
        update_transformations(offset1, offset2)
        #@buf.parser.start_parsing
      end

      def delete_any_mirrors(offset1, offset2)
        @mirrors.each do |num, mirrors|
          (mirrors||[]).reject! do |mirror|
            if mirror[:leftmark].mark.get_offset == mirror[:rightmark].mark.get_offset
              document.delete_mark(mirror[:leftmark].mark)
              document.delete_mark(mirror[:rightmark].mark)
              true
            else
              false
            end
          end
        end
        @mirrors.each do |num, ms|
          if ms.empty?
            @mirrors.delete(num)
          end
        end
      end

      def get_balanced_braces(string)
        defn = []
        line = "$" + string
        finished = false
        depth = 0
        while line.length > 0 and !finished
          if line[0..1] == "\\}"
            defn << line[0..1]
            line = line[2..-1]
           elsif line[0..1] == "\\$"
            defn << line[0..1]
            line = line[2..-1]
          elsif line[0..1] == "${"
            depth += 1
            defn << line[0..1]
            line = line[2..-1]
          elsif line[0..0] == "}"
            depth -= 1
            defn << line[0..0]
            line = line[1..-1]
          else
            defn << line[0..0]
            line = line[1..-1]
          end
          if depth == 0
            return defn.join("")
          end
        end
      end

      def set_names
        @tab_stops.each do |i, h|
          h[:leftmark].name = "$#{i}l"
          h[:rightmark].name = "$#{i}r"
        end
        @mirrors.each do |i, ms|
          ms.each do |m|
            m[:leftmark].name = "m#{i}l"
            m[:rightmark].name = "m#{i}r"
          end
        end
        @transformations.each do |i, ms|
          ms.each do |m|
            m[:leftmark].name = "t#{i}l"
            m[:rightmark].name = "t#{i}r"
          end
        end
      end

      def select_tab_stop(n)
        document.set_selection_range(@tab_stops[n][:rightmark].mark.get_offset,
                                     @tab_stops[n][:leftmark].mark.get_offset)
      end

      def move_forward_tab_stop
        current = find_current_tab_stop
        raise "unexpectedly outside snippet" unless current
        if current == @tab_stops.keys.sort.last
          if @tab_stops.include? 0
            select_tab_stop(0)
          else
            document.cursor_offset = @snippet_end_mark.get_offset
          end
          clear_snippet
        else
          ix = @tab_stops.keys.sort.index(current)
          new_ts = @tab_stops.keys.sort[ix+1]
          if new_ts
            select_tab_stop(new_ts)
          else
            if @tab_stops.include? 0
              select_tab_stop(0)
            else
              document.cursor_offset = @snippet_end_mark.get_offset
            end
          end
        end
      end

      def move_backward_tab_stop
        current = find_current_tab_stop
        raise "unexpectedly outside snippet" unless current
        if current == 1
        else
          select_tab_stop(current-1)
        end
      end

      def clear_snippet
        @current_snippet = false
        @word = nil
        @offset = nil
        @tab_stops = nil
        @snippet_end_mark = nil
        @line = nil
        @mirrors = nil
        @ignore = true
        @marks.each do |mark|
          document.delete_mark(mark.mark)
        end
      end

      def find_current_tab_stop
        candidates = []
        @tab_stops.each do |num, hash|
          leftoff = hash[:leftmark].mark.get_offset
          rightoff = hash[:rightmark].mark.get_offset
          if document.cursor_offset <= rightoff and
             document.cursor_offset >= leftoff and
              document.selection_offset >= leftoff and
              document.selection_offset <= rightoff
            candidates << [(document.cursor_offset - rightoff).abs +
                           (document.selection_offset - leftoff).abs,
                           num]
          end
        end
        unless candidates.empty?
          candidates.sort.first[1]
        end
      end

      def get_tab_stop_range(num)
        off1 = @tab_stops[num][:leftmark].mark.get_offset
        off2 = @tab_stops[num][:rightmark].mark.get_offset
        off1..off2
      end

      def get_tab_stop_text(num)
        i1 = @tab_stops[num][:leftmark].mark.get_offset
        i2 = @tab_stops[num][:rightmark].mark.get_offset
        document.get_slice(i1, i2)
      end

      def insert_duplicate_contents
        update_mirrors
        update_transformations
      end

      def update_mirrors(start=nil, stop=nil)
        @mirrors.each do |num, mirrors|
          next unless mirrors
          r = get_tab_stop_range(num)
          if (!start and !stop) or
              (start >= r.first and start <= r.last) or
              (stop >= r.first and stop <= r.last)
            text = get_tab_stop_text(num)
            mirrors.each do |mirror|
              if document.cursor_offset == mirror[:leftmark].mark.get_offset
                 reset_cursor = true
              end
              @editing_stop_id = mirror[:stop_id]
              i1 = mirror[:leftmark].mark.get_offset
              i2 = mirror[:rightmark].mark.get_offset
              @ignore = true
              document.delete(i1, i2 - i1)
              i1 = mirror[:leftmark].mark.get_offset
              document.insert(i1, text)
              if reset_cursor
                document.cursor_offset = mirror[:leftmark].mark.get_offset
              end
              @ignore = false
            end
          end
        end
        @editing_stop_id = nil
      end

      def update_transformations(start=nil, stop=nil)
        @transformations.each do |num, transformations|
          r = get_tab_stop_range(num)
          if (!start and !stop) or
              (start >= r.first and start <= r.last) or
              (stop >= r.first and stop <= r.last)
            text = get_tab_stop_text(num)
            transformations.each do |trans|
              reset_cursor = false
              @editing_stop_id = trans[:stop_id]
              @ignore = true
              if trans[:global]
                rtext = trans[:replace].grep(text)
              else
                rtext = trans[:replace].rep(text)
              end
              if document.cursor_offset == trans[:leftmark].mark.get_offset
                reset_cursor = true
              end
              i1 = trans[:leftmark].mark.get_offset
              i2 = trans[:rightmark].mark.get_offset
              document.delete(i1, i2 - i1)
              i1 = trans[:leftmark].mark.get_offset
              document.insert(i1, rtext)
              if reset_cursor
                document.cursor_offset = trans[:leftmark].mark.get_offset
              end
              @ignore = false
            end
          end
        end
        @editing_stop_id = nil
      end


    end
  end
end



