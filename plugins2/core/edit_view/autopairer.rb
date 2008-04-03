
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
    
    def invalidate_pairs(mark)
      i = @buf.get_iter_at_mark(mark)
#       puts "cursor_off: #{i.offset}"
#       l = @mark_pairs.length
      @mark_pairs.reject! do |m1, m2|
        i1 = @buf.get_iter_at_mark(m1)
        i2 = @buf.get_iter_at_mark(m2)
        i < i1 or i > i2
      end
#       puts "mark_pairs: #{l} -> #{@mark_pairs.length}"
#       p @mark_pairs.map{|mp| mp.map{|m|@buf.get_iter_at_mark(m).offset}}
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
      # Set up indenting on Return
      @buf.signal_connect_after("insert_text") do |_, iter, text, length|
        @done = nil
        if AutoPairer.autopair_default1.include? text and !@ignore_insert
          end_mark_pair = find_mark_pair_by_end(iter)
          if end_mark_pair
            @buf.delete(@buf.iter(@buf.cursor_offset-1),
                        @buf.cursor_iter)
            @buf.place_cursor(@buf.iter(@buf.cursor_offset+1))
            @done = true
          end
        end
        
        if AutoPairer.autopair_default.include? text and !@ignore_insert and !@done
          @ignore_insert = true
          @buf.insert_at_cursor(AutoPairer.autopair_default[text])
          @buf.place_cursor(@buf.iter(@buf.cursor_offset-1))
          mark1 = @buf.create_mark(nil, @buf.iter(@buf.cursor_offset-1), false)
          mark2 = @buf.create_mark(nil, @buf.cursor_iter, false)
          add_mark_pair [mark1, mark2]
          @ignore_insert = false
        end
        false
      end
      
      @buf.signal_connect("delete_range") do |_, iter1, iter2|
        if iter1.offset == iter2.offset-1 and !@ignore_delete
          @deletion = iter1.offset
        end
      end
      @buf.signal_connect_after("delete_range") do |_, _, _|
        if @deletion and !@ignore_delete
          mark_pair = find_mark_pair_by_start(@buf.iter(@deletion))
          if mark_pair
            @ignore_delete = true
            i = @buf.get_iter_at_mark(mark_pair[1])
            @buf.delete(i, @buf.iter(i.offset+1))
            @ignore_delete = false
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
