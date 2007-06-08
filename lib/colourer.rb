
module Redcar
  class Colourer
    include DebugPrinter
    
    attr_accessor :theme
    
    def initialize(tab, theme)
      @tab = tab
      @theme = theme
      raise ArgumentError, "colourer needs a Redcar::Theme" unless theme.is_a? Theme
    end
    
    def colour_line(scope_tree, line_num, priority=1)
#       buffer = @tab.buffer
#       buffer.remove_all_tags(@tab.line_start(line_num),
#                              @tab.line_end(line_num))
      colour_line1(scope_tree, line_num, nil, nil, priority)
    end
    
    def colour_line1(scope_tree, line_num, sl=nil, el=nil, priority=1)
      buffer = @tab.buffer
      return if scope_tree.children.empty?
      if e=scope_tree.children.first.end and e.line >= line_num
        first_ix = 0
      else
        first_ix  = scope_tree.children.find_flip_index {|cs| !cs.end or cs.end.line >= line_num }
      end
      if scope_tree.children.last.start.line > line_num
        second_ix = 0
      else
        second_ix = scope_tree.children.find_flip_index {|cs| cs.start.line > line_num }
     end
#       puts
#       p first_ix
#       p second_ix
      return unless first_ix
      second_ix = -1 unless second_ix
#       scope_tree.children.each do |scope|
      children_checked = scope_tree.children[first_ix..(second_ix-1)].length
      Instrument(:colourer_children_checked, children_checked)
      count = 0
      for scope in scope_tree.children[first_ix..second_ix]
        if scope.on_line?(line_num)
          count += 1
          #             unless sl
          sl = buffer.get_iter_at_line_offset(scope.start.line, 0)
          #             end
          #             unless el
          el = buffer.get_iter_at_line_offset(scope.start.line+1, 0)
          #             end
          unless scope.start == scope.end
            start_iter = buffer.get_iter_at_offset(sl.offset+minify(scope.start.offset))
            if scope.end
              end_iter   = buffer.get_iter_at_offset(sl.offset+minify(scope.end.offset))
            else
              end_iter = el
              if el.offset == sl.offset
                end_iter = buffer.get_iter_at_offset(buffer.char_count)
              end
            end
            #debug_puts {"  "*priority + 
            #  "#{scope.name+"("+priority.to_s+")"}(#{priority}): #{scope.start.offset}-#{end_iter.line_offset}"}
            unless tag = buffer.tag_table.lookup(scope.name+"("+priority.to_s+")")
              all_settings = @theme.settings_for_scope(scope.name)
              #debug_puts {"  "*priority + all_settings.map{|s| s.inspect}.inspect}
              if all_settings.empty?
                tag = buffer.create_tag(scope.name+"("+priority.to_s+")",
                                        :foreground => theme.global_settings['foreground'])
                tag.priority = priority
              else
                settings = all_settings[0]["settings"]
                tag = buffer.create_tag(scope.name+"("+priority.to_s+")",
                                        Theme.textmate_settings_to_pango_options(settings))
                tag.priority = priority
              end
            end
            if tag
              #debug_puts {"  "*priority + "#{start_iter.offset}-#{end_iter.offset}"}
              #debug_puts {"  "*priority + tag.inspect}
              buffer.apply_tag(tag, start_iter, end_iter)
            end
            colour_line1(scope, line_num, sl, el, priority+1)
          end
        end
      end
      Instrument(:prop_children_on_line, count.to_f/children_checked)
                Instrument(:priority, priority)
    end
    
    # Syntax colours the given buffer from the given scope_tree.
    def colour(scope_tree, priority=1)
      buffer = @tab.buffer
      scope_tree.children.each do |scope|
        begin
           sl = buffer.get_iter_at_line_offset(scope.start.line, 0)
           el = buffer.get_iter_at_line_offset(scope.start.line+1, 0)
          tx = buffer.get_slice(sl, el)
          unless scope.start.offset == scope.end.offset and 
              scope.start.line == scope.end.line
            #debug_puts "#{scope.name+"("+priority.to_s+")"}: #{scope.start.offset}-#{scope.end.offset} (#{tx.length})"
            #debug_puts scope.start
            #debug_puts scope.end
            #debug_puts sl.offset+minify(scope.start.offset)
            #debug_puts sl.offset+minify(scope.end.offset)
            start_iter = buffer.get_iter_at_offset(sl.offset+minify(scope.start.offset))
            end_iter   = buffer.get_iter_at_offset(sl.offset+minify(scope.end.offset))
            unless tag = buffer.tag_table.lookup(scope.name+"("+priority.to_s+")")
              all_settings = @theme.settings_for_scope(scope.name)
              #debug_puts all_settings.map{|s| s.inspect}.inspect
              if all_settings.empty?
                tag = buffer.create_tag(scope.name+"("+priority.to_s+")",
                                        :foreground => theme.global_settings['foreground'])
                tag.priority = priority
              else
                settings = all_settings[0]["settings"]
                tag = buffer.create_tag(scope.name+"("+priority.to_s+")",
                                        Theme.textmate_settings_to_pango_options(settings))
                tag.priority = priority
              end
            end
            if tag
              #debug_puts "#{start_iter.line_offset}-#{end_iter.line_offset}"
              #debug_puts tag.inspect
              buffer.apply_tag(tag, start_iter, end_iter)
            end
            colour(scope, priority+1)
          end
        rescue Object => e
          #debug_puts e
          #debug_puts e.backtrace
        end
      end
    end
    
    def minify(offset)
      [offset, 200].min
    end
  end
end
