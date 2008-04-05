

class Redcar::EditView
  class SnippetInserter
    def self.load_snippets
      @snippets = Hash.new {|h, k| h[k] = {}}
      i = 0
      Redcar::Bundle.names.each do |name|
        snippets = Redcar::Bundle.get(name).snippets
        snippets.each do |snip|
          if snip["tabTrigger"]
            @snippets[snip["scope"]||""][snip["tabTrigger"]] = snip
          else
            i += 1
          end          
        end
      end
      puts "#{i} snippets not loaded because they didn't have tabTriggers"  
      @snippets.default = nil
    end
    
    def self.default_snippets
      @snippets[""]
    end
    
    def self.register(scope, tab_trigger, content)
      @snippets[scope][tab_trigger] = {"content" => content}
    end
    
    def self.snippets_for_scope(scope)
      all_snippets_for_scope = {}
      if scope
        @snippets.each do |scope_selector, snippets_for_scope|
           #       puts "applicable? #{scope_selector} to #{scope.hierarchy_names(true).join(" ")}"
          v = Theme.applicable?(scope_selector, scope.hierarchy_names(true)).to_bool
           #       p v
          if v
       #     p snippets_for_scope
            all_snippets_for_scope.merge! snippets_for_scope
          end
        end
      end
      all_snippets_for_scope
    end
    
    attr_reader(:tab_stops)
    
    def initialize(buffer)
      self.buffer = buffer
      @parser = buffer.parser
      connect_buffer_signals
    end
    
    def connect_buffer_signals
      @buf.signal_connect_after("mark_set") do |widget, event, mark|
        if @in_snippet and mark.name == "insert"
          check_in_snippet
        end
        false
      end
      
      @buf.signal_connect_after("insert_text") do |_, iter, text, length|
        if @in_snippet and !@ignore
          update_after_insert(iter.offset, length)
        end
        false
      end
      
      @buf.signal_connect("delete_range") do |_, iter1, iter2|
        if @in_snippet and !@ignore
          @delete_offset1 = iter1.offset
          @delete_offset2 = iter2.offset
        else
          @delete_offset1 = nil
          @delete_offset2 = nil
        end
        false
      end

      @buf.signal_connect_after("delete_range") do |_, iter1, iter2|
        if @in_snippet and @delete_offset1
          update_after_delete(@delete_offset1,
                              @delete_offset2)
          @delete_offset1 = nil
          @delete_offset2 = nil
        end
        false
      end
    end
    
    def buffer=(buf)
      @buf = buf
    end
    
    def in_snippet?
      @in_snippet
    end
    
    def tab_pressed
      if @in_snippet
        move_forward_tab_stop
        true
      else
        @word = nil
        @offset = nil        
        line = @buf.get_slice(@buf.line_start(@buf.cursor_line),
                              @buf.cursor_iter).reverse
        if line =~ /([^\s]+)(\s|$)/
          @word = $1.reverse
          @offset = @buf.cursor_offset
        end
        if @word
          if default_snippets = SnippetInserter.default_snippets and
              snippet = default_snippets[@word]
            @buf.delete(@buf.iter(@offset-@word.length), 
                        @buf.iter(@offset))
            insert_snippet(snippet)
            true
          elsif snippets_for_scope = SnippetInserter.snippets_for_scope(@buf.cursor_scope) and 
              snippet = snippets_for_scope[@word]
            @buf.delete(@buf.iter(@offset-@word.length), 
                        @buf.iter(@offset))
            insert_snippet(snippet)
            true
          end
        else
          false
        end
      end
    end
    
    def shift_tab_pressed
      if @in_snippet
        move_backward_tab_stop
        true
      end
    end

    def insert_snippet(snippet)
      @in_snippet = true
      content = snippet["content"]
      p content
      @insert_line_num = @buf.cursor_line
      @line = ""
      @tab_stops = {}
      @mirrors = {}
      @transformations = {}
      parse_text_for_tab_stops(content)
      @ignore = true
      @buf.insert_at_cursor(@line)
      create_tab_stop_marks
      fix_indent
      @ignore = false
      insert_contents
      select_tab_stop(1) unless @tab_stops.empty?
    end
        
    def parse_text_for_tab_stops(text)
      remaining_content = text
      i = 0
      while remaining_content.length > 0
        i += 1
        raise "Snippet failed to parse: #{content.inspect}" if i > 100
        
        if  md = remaining_content.match(/\$/)
          @line += md.pre_match
          
          if md1 = md.post_match.match(/^(\d+)/)
            remaining_content = md1.post_match
            # Simple tab stop "... $1 ... "
            if !@tab_stops.include? $1.to_i
              @tab_stops[$1.to_i] = {:offset => @line.length}
            else
              # it's a mirror
              @mirrors[$1.to_i] ||= []
              @mirrors[$1.to_i] << {:offset => @line.length}
            end
            
          elsif md1 = md.post_match.match(/^\{/)
            # tab stop with placeholder string "... ${1:condition ... "
            defn = get_balanced_braces(md.post_match)[1..-2]
            
            if md2 = defn.match(/^(\d+):/)
              # content is a string
              @tab_stops[$1.to_i] = {
                :offset  => @line.length,
                :content => md2.post_match
              }
              remaining_content = md1.post_match[(defn.length+1)..-1]
            elsif md2 = defn.match(/^(\d+)\//)
              # it is a transformation
              bits = defn.split("/")
              @transformations[md2[1].to_i] ||= []
              @transformations[md2[1].to_i] << {
                :offset => @line.length,
                :replace => RegexReplace.new(bits[1], bits[2]),
                :global => bits[3] == "g" ? true : false
              }
              remaining_content = md1.post_match[(defn.length+1)..-1]
            end
          end
        else
          @line += remaining_content
          remaining_content = ""
        end
      end
    end
    
    def fix_indent
      firstline = @buf.get_line(@insert_line_num).to_s.chomp
      if firstline
        if md = firstline.match(/^(\s+)/)
          indent = md[1]
        else
          indent = ""
        end
        lines = @line.scan("\n").length
        lines.times do |i|
          @buf.insert(@buf.line_start(@insert_line_num+i+1), indent)
        end
      end
    end
    
    def create_marks_at_offset(offset)
      left = @buf.create_mark(
                              nil, 
                              @buf.iter(@buf.cursor_offset - @line.length +
                                        offset),
                              true)
      right = @buf.create_mark(
                               nil, 
                               @buf.iter(@buf.cursor_offset - @line.length +
                                         offset),
                               false)
      return left, right
    end
    
    def create_tab_stop_marks
      @tab_stops.each do |num, hash|
        left, right = create_marks_at_offset(hash[:offset])
        hash[:leftmark] = left
        hash[:rightmark] = right
      end
      @mirrors.each do |num, hashes|
        hashes.each do |hash|
          left, right = create_marks_at_offset(hash[:offset])
          hash[:leftmark] = left
          hash[:rightmark] = right
        end
      end
      @transformations.each do |num, hashes|
        hashes.each do |hash|
          left, right = create_marks_at_offset(hash[:offset])
          hash[:leftmark] = left
          hash[:rightmark] = right
        end
      end
      unless @tab_stops.include? 0
        @snippet_end_mark = @buf.create_mark(nil, @buf.cursor_iter, false)   
      end
    end
    
    def insert_contents
      @tab_stops.each do |num, hash|
        if hash[:content]
          @buf.insert(@buf.iter(hash[:leftmark]), hash[:content])
        end
      end
    end
    
    def find_current_tab_stop
      @tab_stops.each do |num, hash|
        leftoff = @buf.iter(hash[:leftmark]).offset
        rightoff = @buf.iter(hash[:rightmark]).offset
        if @buf.cursor_offset <= rightoff and 
            @buf.cursor_offset >= leftoff
          return num
        end
      end
      nil
    end
    
    def print_tab_stop_info
      @tab_stops.each do |num, hash|
        puts "tab #{num}: #{@buf.iter(hash[:leftmark]).offset} #{@buf.iter(hash[:rightmark]).offset}"
      end
    end
    
    def get_balanced_braces(string)
      defn = []
      line = string
      finished = false
      depth = 0
      while line.length > 0 and !finished
        if line[0..1] == "\\{" or 
            line[0..1] == "\\}"
          defn << line.at(0)
          defn << line.at(1)
          line = line[2..-1]
        elsif line.at(0) == "{"
          depth += 1
          defn << line.at(0)
          line = line[1..-1]
        elsif line.at(0) == "}"
          depth -= 1
          defn << line.at(0)
          line = line[1..-1]
        else
          defn << line.at(0)
          line = line[1..-1]
        end
        if depth == 0
          return defn.join("")
        end
      end
    end

    def move_forward_tab_stop
      current = find_current_tab_stop
      raise "unexpectedly outside snippet" unless current
      if current == @tab_stops.keys.sort.last
        if @tab_stops.include? 0
          select_tab_stop(0)
        else
          @buf.place_cursor(@buf.iter(@snippet_end_mark))
        end
        clear_snippet
      else
        select_tab_stop(current+1)
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
    
    def select_tab_stop(n)
      @buf.select(@buf.iter(@tab_stops[n][:leftmark]),
                  @buf.iter(@tab_stops[n][:rightmark]))
    end
    
    def check_in_snippet
      clear_snippet unless find_current_tab_stop
    end
    
    def clear_snippet
      @in_snippet = false
      @word = nil
      @offset = nil
      @tab_stops = nil
      @snippet_end_mark = nil
      @line = nil
      @mirrors = nil
      @ignore = true
    end
    
    def get_tab_stop_range(num)
      off1 = @buf.iter(@tab_stops[num][:leftmark]).offset
      off2 = @buf.iter(@tab_stops[num][:rightmark]).offset
      off1..off2
    end
    
    def get_tab_stop_text(num)
      i1 = @buf.iter(@tab_stops[num][:leftmark])
      i2 = @buf.iter(@tab_stops[num][:rightmark])
      @buf.get_slice(i1, i2)
    end
    
    def update_mirrors(start, stop)
      @mirrors.each do |num, mirrors|
        r = get_tab_stop_range(num)
        if (start >= r.first and start <= r.last) or
            (stop >= r.first and stop <= r.last)
          text = get_tab_stop_text(num)
          mirrors.each do |mirror|
            i1 = @buf.iter(mirror[:leftmark])
            i2 = @buf.iter(mirror[:rightmark])
            @ignore = true
            @buf.delete(i1, i2)
            @buf.insert(@buf.iter(mirror[:leftmark]), text)
            @ignore = false
          end
        end
      end
    end
    
    def update_transformations(start, stop)
      @transformations.each do |num, transformations|
        r = get_tab_stop_range(num)
        if (start >= r.first and start <= r.last) or
            (stop >= r.first and stop <= r.last)
          text = get_tab_stop_text(num)
          transformations.each do |trans|
            i1 = @buf.iter(trans[:leftmark])
            i2 = @buf.iter(trans[:rightmark])
            @ignore = true
            @buf.delete(i1, i2)
            if trans[:global]
              rtext = trans[:replace].grep(text)
            else
              rtext = trans[:replace].rep(text)
            end
            @buf.insert(@buf.iter(trans[:leftmark]), rtext)
            @ignore = false
          end
        end
      end
    end
    
    def update_after_insert(offset, length)
      update_mirrors(offset, offset+length)
      update_transformations(offset, offset+length)
    end
    
    def update_after_delete(offset1, offset2)
      update_mirrors(offset1, offset2)
      update_transformations(offset1, offset2)
    end
  end
end
