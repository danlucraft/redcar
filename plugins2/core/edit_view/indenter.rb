
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
#        puts "applicable? #{scope_name} to #{scope.hierarchy_names(true).join(" ")}"
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
        if text == "\n" and !@ignore
          rules = Indenter.indent_rules_for_scope(@parser.starting_scopes[line_num-1])
          @parser.delay_parsing do
            indent_line(line_num-1, rules) if line_num > 0
            indent_line(line_num, rules)
            line = @buf.get_line(line_num).to_s
            if contains_decrease_indent(line, rules) and
                !contains_increase_indent(line, rules) and
                !contains_nonindented(line, rules) and 
                !contains_indent_next(line, rules)
              @ignore = true
              @buf.insert(@buf.line_start(line_num), "\n")
              @buf.place_cursor(@buf.line_start(line_num))
              @ignore = false
              indent_line(line_num, rules)
            end
          end
        end
        false
      end
    end
    
    def contains_increase_indent(line, rules)
      re = rules[:increase]
      re.match(line) if re
    end
    
    def contains_decrease_indent(line, rules)
      re = rules[:decrease]
      re.match(line) if re
    end
    
    def contains_nonindented(line, rules)
      re = rules[:noindent]
      re.match(line) if re
    end
    
    def contains_indent_next(line, rules)
      re = rules[:nextline]
      re.match(line) if re
    end
    
    def indent_line(line_num, rules=nil)
      rules ||= Indenter.indent_rules_for_scope(@parser.starting_scopes[line_num-1])
#       puts "indent_line: #{line_num}"
      cursor_offset = @buf.cursor_line_offset
#       puts "cursor_line_offset: #{cursor_offset}"
      prev2line = @buf.get_line(line_num-2)
      prevline  = @buf.get_line(line_num-1)
      currline  = @buf.get_line(line_num)
#       puts "  prev2line:#{prev2line.inspect}"
#       puts "  prevline: #{prevline.inspect}"
#       puts "  currline: #{currline.inspect}"
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
      currline.string.chomp =~ /^(\s*)(.*)/
      currline_indent = $1
      currline_indent_length = get_indent_size(currline_indent, indent_type)
      set_line_indent(line_num, new_length, indent_type)
    end
    
    def set_line_indent(line_num, indent_size, indent_type)
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
      line_off = @buf.line_start(line_num).offset
      @buf.delete(@buf.iter(line_off), @buf.iter(line_off+$1.length))
      @buf.insert(@buf.line_start(line_num), new_indent)
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
  end
end
