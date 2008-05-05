class Gtk::SourceMarker
  attr_accessor :name
end

class Redcar::EditView
  class SnippetInserter
    def self.load_snippets
      @snippets = Hash.new {|h, k| h[k] = {}}
      i = 0
      Redcar::Bundle.names.each do |name|
        snippets = Redcar::Bundle.get(name).snippets
        snippets.each do |snip|
          safename = snip["name"].gsub("/", "SLA").gsub("\"", "\\\"").gsub("#", "\\\#")
          slot = bus("/textmate/bundles/#{name}/#{safename}")
          slot.data = snip
          if snip["tabTrigger"]
            @snippets[snip["scope"]||""][snip["tabTrigger"]] = snip
#          elsif snip["keyEquivalent"]
#            keyb = Redcar::Bundle.translate_key_equivalent(snip["keyEquivalent"])
#            if keyb
#              command_class = Class.new(Redcar::Command)
#              if snip["scope"]
#                command_class.class_eval %Q{
#                  scope "#{snip["scope"]}"
#                }
#              end
#              t= %Q{
#                key "Global/#{keyb.gsub("\"", "\\\"").gsub("#", "\\\#")}"
##                sensitive :edit_tab?
#                def execute
#                  tab.view.snippet_inserter.insert_snippet_from_path("#{slot.path}")
#                end
#              }
#              command_class.class_eval t
#            end
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
        if @in_snippet and mark == @buf.cursor_mark
          check_in_snippet
        end
        false
      end
      
      @buf.signal_connect("insert_text") do |_, iter, text, length|
        @insert_offset = nil
        if @in_snippet and !@ignore
          @buf.parser.parsing_on = false
          @insert_offset = iter.offset
        end
        false
      end
      
      @buf.signal_connect_after("insert_text") do |_, iter, text, length|
        if @in_snippet and !@ignore and @insert_offset
          update_after_insert(@insert_offset, length)
          @buf.parser.parsing_on = true
          @buf.parser.process_changes
          @insert_offset = nil
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

    def unescape_dollars(text)
      text.gsub("\\$", "$").gsub("\\\\", "\\")
    end
    
    def insert_snippet_from_path(path)
      insert_snippet(bus(path).data)
    end
    
    def insert_snippet(snippet)
      p snippet
      @in_snippet = true
      @content = snippet["content"]
      @insert_line_num = @buf.cursor_line
      @tab_stops = {}
      @mirrors = {}
      @transformations = {}
      @ignore = true
      Redcar::App.set_environment_variables
      @content = execute_backticks(@content)
      @buf.parser.delay_parsing do
        parse_text_for_tab_stops(@content)
        unless @tab_stops.include? 0
          @snippet_end_mark = @buf.create_mark(nil, @buf.cursor_iter, false)   
        end
        fix_indent
        create_right_marks
        insert_duplicate_contents
      end
      @ignore = false
      select_tab_stop(1) unless @tab_stops.empty?
    end

    def parse_text_for_tab_stops(text)
#      puts "parse_text_for_tab_stops(#{text.inspect})"
      remaining_content = text
      i = 0
      while remaining_content.length > 0
        i += 1
        raise "Snippet failed to parse: #{text.inspect}" if i > 100
        
        if md = Oniguruma::ORegexp.new("(?<!\\\\)\\$").match(remaining_content)
          @buf.insert_at_cursor(unescape_dollars(md.pre_match))

          if md1 = md.post_match.match(/\A(\d+)/)
            remaining_content = md1.post_match
            # Simple tab stop "... $1 ... "
            if !@tab_stops.include? $1.to_i
              left = create_mark_at_offset(@buf.cursor_offset)
              @tab_stops[$1.to_i] = {:leftmark => left}
            else
              # it's a mirror
              left = create_mark_at_offset(@buf.cursor_offset)
              @buf.insert_at_cursor("LR")
              @mirrors[$1.to_i] ||= []
              @mirrors[$1.to_i] << {:leftmark => left}
            end
          elsif md1 = md.post_match.match(/\A((\w+|_)+)\b/)
            @buf.insert_at_cursor(ENV[$1]||"")
            # it is an environment variable " ... $TM_LINE_NUMBER ... "
            remaining_content = md1.post_match
          elsif md1 = md.post_match.match(/\A\{/)
            # tab stop with placeholder string "... ${1:condition ... "
            defn = get_balanced_braces(md.post_match)[1..-2]
            
            if md2 = defn.match(/\A(\d+):/)
              # placeholder is a string
              left = @buf.create_mark(nil, @buf.iter(@buf.cursor_offset), true)
#              @buf.insert(@buf.iter(@buf.cursor_offset-1), md2.post_match)
              parse_text_for_tab_stops(md2.post_match)
              right = @buf.create_mark(nil, @buf.iter(@buf.cursor_offset), true)
              if !@tab_stops.include? md2[1].to_i
                @tab_stops[md2[1].to_i] = {:leftmark => left, :rightmark => right}
              else
                # it's a mirror
                @mirrors[md2[1].to_i] ||= []
                @mirrors[md2[1].to_i] << {:leftmark => left, :rightmark => right}
              end
              remaining_content = md1.post_match[(defn.length+1)..-1]
            elsif md2 = defn.match(/\A(\d+)\//)
              # placeholder is a transformation
              bits = defn.onig_split(ORegexp.new("(?<!\\\\)/"))
              bits[2] = bits[2].gsub("\\/", "/")
              left = create_mark_at_offset(@buf.cursor_offset)
              @transformations[md2[1].to_i] ||= []
              @transformations[md2[1].to_i] << {
                :leftmark => left,
                :replace => RegexReplace.new(bits[1], bits[2]),
                :global => bits[3] == "g" ? true : false
              }
              remaining_content = md1.post_match[(defn.length+1)..-1]
            elsif md2 = defn.match(/\A((\w+|_)+)$/)
              # naked environment variable
              @buf.insert_at_cursor(ENV[$1]||"")
              remaining_content = md1.post_match[(defn.length+1)..-1]
            elsif md2 = defn.match(/\A((\w+|_)+)\//)
              # transformed env variable
              env = ENV[$1]||""
              bits = md2.post_match.onig_split(ORegexp.new("(?<!\\\\)/"))
              bits[1] = bits[1].gsub("\\/", "/")
              rr = RegexReplace.new(bits[0], bits[1])
              if bits[2] == "g"
                tenv = rr.grep(env)
              else
                tenv = rr.rep(env)
              end
              @buf.insert_at_cursor(tenv)
              remaining_content = md1.post_match[(defn.length+1)..-1]
            else
              puts "unknown type of tab stop: #{defn.inspect}"
              remaining_content = md1.post_match[(defn.length+1)..-1]
            end
          end
        else
          @buf.insert_at_cursor(unescape_dollars(remaining_content))
          remaining_content = ""
        end
      end
    end
    
    def execute_backticks(text)
      text.gsub!(/`(.*)`/m) do |sh|
        %x{#{sh[1..-2]}}.chomp
      end
      text
    end
    
    def fix_indent
      firstline = @buf.get_line(@insert_line_num).to_s.chomp
      if firstline
        if md = firstline.match(/^(\s+)/)
          indent = md[1]
        else
          indent = ""
        end
        lines = @content.scan("\n").length
        lines.times do |i|
          @buf.insert(@buf.line_start(@insert_line_num+i+1), indent)
        end
      end
    end
    
    def create_mark_at_offset(offset)
      @buf.create_mark(nil, 
                       @buf.iter(offset),
                       true)
    end
    
    def create_right_marks
      hashes = []
      @tab_stops.each {|_, h| hashes << h}
      @mirrors.each {|_, hs| hs.each {|h| hashes << h}}
      @transformations.each {|_, hs| hs.each {|h| hashes << h}}
      hashes.each do |hash|
        if right = hash[:rightmark]
          new_right = @buf.create_mark(nil, @buf.iter(right), false)
          hash[:rightmark] = new_right
          @buf.delete_mark(right)
        else
          new_right = @buf.create_mark(nil, @buf.iter(hash[:leftmark]), false)
          hash[:rightmark] = new_right
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
    
    def insert_duplicate_contents
      set_names
      @mirrors.each do |num, mirrors|
        text = get_tab_stop_text(num)
        puts "mirror: #{num}" 
        puts "  before: #{debug_text.inspect}"
        mirrors.each do |mirror|
          i1 = @buf.iter(mirror[:leftmark])
          i2 = @buf.iter(mirror[:rightmark])
          @ignore = true
          @buf.delete(i1, i2)
          puts "  text: #{text}" 
          @buf.insert(@buf.iter(mirror[:leftmark]), text)
          puts "  after: #{debug_text.inspect}"
          @ignore = false
        end
      end
      @transformations.each do |num, transformations|
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
    
    def find_current_tab_stop
      candidates = []
      @tab_stops.each do |num, hash|
        leftoff = @buf.iter(hash[:leftmark]).offset
        rightoff = @buf.iter(hash[:rightmark]).offset
        if @buf.cursor_offset <= rightoff and 
            @buf.selection_offset >= leftoff
          candidates << [(@buf.cursor_offset-rightoff).abs+
                         (@buf.selection_offset-leftoff).abs,
                         num]
        end
      end
      unless candidates.empty?
        candidates.sort.first[1]
      end
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
      if n == 0
        @buf.select(@buf.iter(@tab_stops[n][:rightmark]),
                    @buf.iter(@tab_stops[n][:rightmark]))
      else
        @buf.select(@buf.iter(@tab_stops[n][:leftmark]),
                    @buf.iter(@tab_stops[n][:rightmark]))
      end
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
      @buf.parser.delay_parsing do
        update_mirrors(offset, offset+length)
        update_transformations(offset, offset+length)
      end
    end
    
    def update_after_delete(offset1, offset2)
      @buf.parser.delay_parsing do
        update_mirrors(offset1, offset2)
        update_transformations(offset1, offset2)
      end
    end
    
    def debug_text
      text = @buf.text
      length = text.length
      i = 0
      p = 0
      while i < length+1
        marks = @buf.get_iter_at_offset(i).marks
        marks.each do |mark|
          marktext = "<#{mark.name}>"
          text.insert(p, marktext)
          p += marktext.length
        end
        i += 1
        p += 1
      end
      text
    end
  end
end
