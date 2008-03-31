
class Redcar::EditView
  class Indenter
    def self.lookup_indent_rules
      @indent_rules = Hash.new {|h, k| h[k] = {}}
      Redcar::Bundle.names.each do |name|
        prefs = Redcar::Bundle.get(name).preferences
        prefs.each do |pref_name, pref_hash|
          scope = pref_hash["scope"]
          if scope
            pref_hash["settings"].each do |set_name, set_value|
              if set_name == "increaseIndentPattern"
                @indent_rules[scope][:increase] = Oniguruma::ORegexp.new(set_value)
              elsif set_name == "decreaseIndentPattern"
                @indent_rules[scope][:decrease] = Oniguruma::ORegexp.new(set_value)
              elsif set_name == "indentNextLinePattern"
                @indent_rules[scope][:nextline] = Oniguruma::ORegexp.new(set_value)
              elsif set_name == "unIndentedLinePattern"
                @indent_rules[scope][:noindent] = Oniguruma::ORegexp.new(set_value)
              end
            end
          end
        end
      end
      @indent_rules.default = nil
    end
    
    def self.indent_rules_for_scope(scope)
      @indent_rules.each do |scope_name, value|
#        puts "applicable? #{scope_name} to #{scope.hierarchy_names(true)}" #.join(" ")}"
        v = Theme.applicable?(scope_name, scope.hierarchy_names(true)).to_bool
#        p v
        if v
          return value
        end
      end
      nil
    end
    
    def initialize(buffer, parser)
      self.buffer = buffer
      @parser = parser
    end
    
    def buffer=(buf)
      @buf = buf
      connect_buffer_signals
    end
    
    def connect_buffer_signals
      # Set up indenting on Return
      @buf.signal_connect_after("insert_text") do |_, iter, text, length|
        line_num = iter.line
        if text == "\n"
          indent_line(line_num-1) if line_num > 1
          indent_line(line_num)   if line_num > 0
        end
        false
      end
    end
    
    def indent_delta(line_num)
      if line_num == 0
        return 0
      end
      line = @buf.get_line(line_num-1)
      currline = @buf.get_line(line_num-1)
      rules = Indenter.indent_rules_for_scope(@parser.scope_at_line_start(line_num-1))
      re_increase    = rules[:increase]
      re_decrease    = rules[:decrease]
      re_indent_next = rules[:nextline]
      re_unindented  = rules[:noindent]
      bool_increase    = re_increase.match(line)
      bool_decrease    = re_decrease.match(line)
      bool_indent_next = re_indent_next.match(line)
      bool_unindented  = re_unindented.match(line)
      if bool_unindented
        return -1000
      end
    end
    
    def indent_line(line_num)
#      puts "indent_line: #{line_num}"
      cursor_offset = @buf.cursor_line_offset
#      puts "cursor_line_offset: #{cursor_offset}"
      prev2line = @buf.get_line(line_num-2)
      prevline  = @buf.get_line(line_num-1)
      currline  = @buf.get_line(line_num)
#      puts "  prev2line:#{prev2line.inspect}"
#      puts "  prevline: #{prevline.inspect}"
#      puts "  currline: #{currline.inspect}"
      rules = Indenter.indent_rules_for_scope(@parser.starting_scopes[line_num-1])
      unless rules
        puts "no rules for indenting line"
        return
      end
      re_increase    = rules[:increase]
      re_decrease    = rules[:decrease]
      re_indent_next = rules[:nextline]
      re_unindented  = rules[:noindent]
      bool_increase, bool_decrease, bool_indent_next, bool_indent_next2, bool_unindented = nil, nil, nil, nil, nil
      bool_increase    = re_increase.match(prevline).to_bool    if re_increase and prevline
      bool_decrease    = re_decrease.match(currline).to_bool    if re_decrease and prevline
      bool_indent_next = re_indent_next.match(prevline).to_bool if re_indent_next and prevline
      bool_indent_next2 = re_indent_next.match(prev2line).to_bool if re_indent_next and prev2line
      bool_unindented2  = re_unindented.match(prev2line).to_bool  if re_unindented and prev2line
      bool_unindented1  = re_unindented.match(prevline).to_bool  if re_unindented and prevline
      bool_unindented  = re_unindented.match(currline).to_bool  if re_unindented
#       puts "  #{bool_increase.inspect}, #{bool_decrease.inspect}, #{bool_indent_next.inspect},"+
#         " #{bool_indent_next2.inspect}, #{bool_unindented.inspect}, #{bool_unindented1.inspect}, "+
#         "#{bool_unindented2.inspect}"
      if bool_unindented and currline.string.chomp != ""
#        puts "  :unindented line"
        set_line_indent(line_num, 0, :spaces)
        return
      end
      if prevline
        prevline.string.chomp =~ /^(\s*)(.*)/
        previous_indent = $1
        if prev2line
          prev2line.string.chomp =~ /^(\s*)(.*)/
          previous_indent2 = $1
          indent_type = get_indent_type(previous_indent, previous_indent2)
          previous_length2 = get_indent_size(previous_indent2, indent_type)
        else
          previous_length2 = 0
          indent_type = get_indent_type(previous_indent)
        end
        previous_length = get_indent_size(previous_indent, indent_type)
        if bool_indent_next2 and !bool_unindented2
          previous_length -= 1
        end
      else
        indent_type = get_indent_type("")
        previous_length = 0
        previous_length2 = 0
      end
#      puts "  previous_length: #{previous_length}"
      if bool_unindented1
        set_line_indent(line_num, previous_length2, indent_type)
        return
      else
        new_length = previous_length
      end
      if (bool_increase and !bool_decrease) or bool_indent_next
        new_length += 1
      elsif bool_decrease and !bool_increase
        new_length -= 1
      end
      new_length = [new_length, 0].max
#      puts "  new_length:#{new_length}"
      currline.string.chomp =~ /^(\s*)(.*)/
      currline_indent = $1
      currline_indent_length = get_indent_size(currline_indent, indent_type)
      unless new_length == currline_indent_length
        set_line_indent(line_num, new_length, indent_type)
        if indent_type == :spaces
          stops = Redcar::Preference.get("Editing/Indent size").to_i
          @buf.cursor = TextLoc(line_num, cursor_offset+(new_length-currline_indent_length)*stops)
        else
          @buf.cursor = TextLoc(line_num, cursor_offset+new_length-currline_indent_length)
        end
      end
    end
    
    def set_line_indent(line_num, indent_size, indent_type)
#      puts "  set_line_indent(#{line_num}, #{indent_size})"
      cursor_on_line = ( @buf.cursor_line == line_num )
      currline  = @buf.get_line(line_num)
      currline.string.chomp =~ /^(\s*)(.*)/
      text = $2
      case indent_type
      when :spaces
        stops = Redcar::Preference.get("Editing/Indent size").to_i
        new_indent = " "*stops*indent_size
      when :tabs
        new_indent = "\t"*indent_size
      end
      new_indent
      @buf.delete(@buf.line_start(line_num), @buf.line_end1(line_num))
      @buf.insert(@buf.line_start(line_num), new_indent + text)
      if cursor_on_line
        new_cursor_offset = @buf.line_start(line_num).offset + new_indent.length
        @buf.place_cursor(@buf.iter(new_cursor_offset))
      end
    end
    
    def get_indent_size(indent, type)
      stops = Redcar::Preference.get("Editing/Indent size").to_i
      case type
      when :spaces
        indent.length/stops
      when :tabs
        indent.length
      end
    end
      
    def get_indent_type(indent1, indent2="")
      pref = Redcar::Preference.get("Editing/Use spaces instead of tabs").to_bool
      if indent1.include? "\t" 
        :tabs
      elsif indent1.include? " "
        :spaces
      elsif indent2.include? "\t"
        :tabs
      elsif indent2.include? " "
        :spaces
      else
        if pref
          :spaces
        else
          :tabs
        end
      end
    end
    
    # Indents line line_num according to the indenting on the previous
    # line and whether the previous and current line have any
    # starting or stopping fold markers. Repositions the cursor to
    # before the text on the line if the cursor was already on the 
    # line.
    def indent_line1(line_num)
      cursor_on_line = ( @buf.cursor_line == line_num )
      delta = indent_delta(line_num)
      next_delta = indent_delta(line_num+1)
      preline = @buf.get_line(line_num-1)
      line = @buf.get_line(line_num)
      if delta == 1 and next_delta == -1
        delta = 0
      elsif next_delta == -1
        delta = -1
      elsif delta == -1
        delta = 0
      end
      line.string.chomp =~ /^(\s*)(.*)/
      curr_indent = $1
      curr_text   = $2
      preline.string.chomp =~ /^(\s*)(.*)/
      pre_indent  = $1
      pre_text    = $2
      if pre_indent.include? "\t" and pre_indent.include? " "
        puts "inconsistent use of tabs and spaces! No indenting."
      elsif pre_indent.include? "\t" or pre_indent == ""
        pre_length = pre_indent.length
        post_length = [pre_length+delta, 0].max
        @buf.delete(@buf.line_start(line_num), @buf.line_end1(line_num))
        @buf.insert(@buf.line_start(line_num), "\t"*post_length+curr_text)
      elsif curr_indent.include? " " or curr_indent == ""
        insize = Redcar::Preference.get("Editing/Indent size")
        pre_length = pre_indent.length
        post_length = [pre_length+delta*insize, 0].max
        @buf.delete(@buf.line_start(line_num), @buf.line_end1(line_num))
        @buf.insert(@buf.line_start(line_num), " "*post_length+curr_text)
      end
      if cursor_on_line
        cursor_offset = @buf.line_start(line_num).offset+post_length
        @buf.place_cursor(@buf.iter(cursor_offset))
      end
      line = @buf.get_line(line_num)
    end
    
  end
end
