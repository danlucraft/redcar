
class Redcar::EditView
  class AutoPairer
    def self.lookup_autopair_rules
      @autopair_rules = Hash.new {|h, k| h[k] = {}}
      @autopair_default = nil
      Redcar::Bundle.names.each do |name|
        prefs = Redcar::Bundle.get(name).preferences
        prefs.each do |pref_name, pref_hash|
          scope = pref_hash["scope"]
          if scope
            pref_hash["settings"].each do |set_name, set_value|
              if set_name == "smartTypingPairs"
                @autopair_rules[scope] = Hash[*set_value.flatten]
              end
            end
          else
            pref_hash["settings"].each do |set_name, set_value|
              if set_name == "smartTypingPairs"
                @autopair_default = Hash[*set_value.flatten]
              end
            end
          end
        end
      end
      if @autopair_default
        @autopair_default1 = @autopair_default.invert
      end
      @autopair_rules.default = nil
    end

    def self.autopair_rules_for_scope(hierarchy_names)
      if hierarchy_names
        @autopair_rules.each do |scope_name, value|
         #         puts "applicable? #{scope_name.inspect} to #{hierarchy_names.join(" ").inspect}"
          v = Theme.applicable?(scope_name, hierarchy_names).to_bool
        #          p v
          if v
            return value
          end
        end
      end
      @autopair_default
    end
    
    cattr_reader :autopair_rules, :autopair_default, :autopair_default1
    attr_reader  :mark_pairs
    
    def initialize(buffer, parser)
      self.buffer = buffer
      @parser = parser
      @mark_pairs = []
    end
    
    def buffer=(buf)
      @buf = buf
      connect_buffer_signals
    end
    
    def add_mark_pair(pair)
      @mark_pairs << pair
#       p :registered_pair
#       p pair.map{|m| @buf.get_iter_at_mark(m).offset}
      if @mark_pairs.length > 10
        p :Whoah_many_pairs
      end
    end
    
    # Forget about pairs if the cursor moves from within them
    def invalidate_pairs(mark)
      i = @buf.get_iter_at_mark(mark)
      @mark_pairs.reject! do |m1, m2|
        i1 = @buf.get_iter_at_mark(m1)
        i2 = @buf.get_iter_at_mark(m2)
        i < i1 or i > i2
      end
    end
    
    def inspect_pairs
      @mark_pairs.map{|mp| mp.map{|m|@buf.get_iter_at_mark(m).offset}}
    end
    
    def find_mark_pair_by_start(iter)
      @mark_pairs.find do |m1, m2| 
        @buf.get_iter_at_mark(m1) == iter
      end
    end
    
    def find_mark_pair_by_end(iter)
      @mark_pairs.find do |m1, m2| 
        @buf.get_iter_at_mark(m2) == iter
      end
    end
    
    def connect_buffer_signals
      # record the scope details BEFORE the new text is inserted
      # as the new text could change them. (ex: HTML incomplete.illegal.
      # tag)
      @buf.signal_connect("insert_text") do |_, iter, text, length|
        cursor_scope = @buf.scope_at(@buf.cursor_line, 
                                      @buf.cursor_line_offset)
        if cursor_scope
          hierarchy_names = cursor_scope.hierarchy_names(true)
          
          # Type over ends
          @rules = AutoPairer.autopair_rules_for_scope(hierarchy_names)
          inverse_rules = @rules.invert
          if inverse_rules.include? text and !@ignore_insert
            end_mark_pair = find_mark_pair_by_end(iter)
            if end_mark_pair and end_mark_pair[3] == text
              @type_over_end = true
              @buf.parser.stop_parsing
            end
          end
          
          # Insert matching ends
          if @rules.include? text and !@ignore_insert and !@done
            @insert_end = true
            @buf.parser.stop_parsing
          end
        end
        false
      end
      
      @buf.signal_connect_after("insert_text") do |_, iter, text, length|
        @done = nil
        
        # Type over ends
        if @type_over_end
          @buf.delete(@buf.iter(@buf.cursor_offset-1),
                      @buf.cursor_iter)
          @buf.place_cursor(@buf.iter(@buf.cursor_offset+1))
          @type_over_end = false
          @buf.parser.start_parsing
          @done = true
        end
        
        # Insert matching ends
        if @insert_end and !@ignore_insert
          @ignore_insert = true
          endtext = @rules[text]
          @buf.insert_at_cursor(endtext)
          @buf.place_cursor(@buf.iter(@buf.cursor_offset-1))
          mark1 = @buf.create_mark(nil, @buf.iter(@buf.cursor_offset-1), false)
          mark2 = @buf.create_mark(nil, @buf.cursor_iter, false)
          add_mark_pair [mark1, mark2, text, endtext]
          @ignore_insert = false
          @buf.parser.start_parsing
          @insert_end = false
        end
        false
      end
      
      @buf.signal_connect("delete_range") do |_, iter1, iter2|
        if iter1.offset == iter2.offset-1 and !@ignore_delete
          @deletion = iter1.offset
        end
      end
      
      @buf.signal_connect_after("delete_range") do |_, _, _|
        # Delete end if start deleted
        if @deletion and !@ignore_delete
          mark_pair = find_mark_pair_by_start(@buf.iter(@deletion))
          if mark_pair
            @ignore_delete = true
            i = @buf.get_iter_at_mark(mark_pair[1])
            @buf.delete(i, @buf.iter(i.offset+1))
            @ignore_delete = false
            @mark_pairs.delete(mark_pair)
            @deletion = nil
          end
        end
      end
      
      @buf.signal_connect_after("mark_set") do |widget, event, mark|
        if mark.name == "insert"
          invalidate_pairs(mark)
        end
      end
    end
    
  end
end
