
module Redcar
  class Colourer
    #include DebugPrinter
    
    attr_accessor :theme
    
    def initialize(sourceview, theme)
      @sourceview = sourceview
      @buffer = @sourceview.buffer
      @theme = theme
      raise ArgumentError, "colourer needs a Redcar::Theme" unless theme.is_a? Theme
    end
    
    def get_start_end_iters(scope,inner)
      if inner
        get_start_end_iters_inner(scope)
      else
        get_start_end_iters_outer(scope)
      end
    end
    
    def get_start_end_iters_inner(scope)
      sl = @buffer.get_iter_at_line_offset(scope.start.line, 0)
      start_iter = @buffer.get_iter_at_offset(sl.offset+minify(scope.open_end.offset))
      if scope.end
        el = @buffer.get_iter_at_line_offset(scope.close_start.line, 0)
        end_iter = @buffer.get_iter_at_offset(el.offset+minify(scope.close_start.offset))
      else
        el = @buffer.get_iter_at_line_offset(scope.open_end.line+1, 0)
        end_iter = el
        if el.offset == sl.offset
          end_iter = @buffer.get_iter_at_offset(@buffer.char_count)
        end
      end
      return start_iter, end_iter
    end
    
    def get_start_end_iters_outer(scope)
      sl = @buffer.get_iter_at_line_offset(scope.start.line, 0)
      start_iter = @buffer.get_iter_at_offset(sl.offset+minify(scope.start.offset))
      if scope.end
        el = @buffer.get_iter_at_line_offset(scope.end.line, 0)
        end_iter   = @buffer.get_iter_at_offset(el.offset+minify(scope.end.offset))
      else
        el = @buffer.get_iter_at_line_offset(scope.start.line+1, 0)
        end_iter = el
        if el.offset == sl.offset
          end_iter = @buffer.get_iter_at_offset(@buffer.char_count)
        end
      end
      return start_iter, end_iter
    end
    
    def colour_scope(scope, inner=true)
      @buffer = @sourceview.buffer
      start_iter, end_iter = get_start_end_iters(scope, inner)
      all_settings = @theme.settings_for_scope(scope, inner)
      #SyntaxLogger.debug "  "*scope.priority+"<"+scope.hierarchy_names(inner).join("\n  "+"  "*scope.priority)+">"
#      all_settings.each {|s| SyntaxLogger.debug "  "*(scope.priority)+ s.inspect}
      if all_settings.empty?
        tag_reference = "default ("+scope.priority.to_s+")"
        settings_hash = {:foreground => theme.global_settings['foreground']}
      else
        settings = all_settings[0]["settings"]
        #               p all_settings
        #               p settings
        tag_reference = all_settings[0]["scope"]+" ("+scope.priority.to_s+")"
        settings_hash = Theme.textmate_settings_to_pango_options(settings)
      end
      unless tag = @buffer.tag_table.lookup(tag_reference)
        tag = @buffer.create_tag(tag_reference, settings_hash)
        tag.priority = scope.priority-1
      end
      #SyntaxLogger.debug {"  "*scope.priority + 
      #  "tag:#{tag_reference}: (#{start_iter.line}, #{start_iter.line_offset})-"+
      #  "(#{end_iter.line}, #{end_iter.line_offset})"}
      if tag
        #SyntaxLogger.debug {"  "*scope.priority + "#{start_iter.offset}-#{end_iter.offset}"}
        #SyntaxLogger.debug {"  "*scope.priority + tag.inspect}
        @buffer.apply_tag(tag, start_iter, end_iter)
      end
    end
    
    def colour_line_with_scopes(line_num, scopes)
      @buffer = @sourceview.buffer
      start_iter = @buffer.get_iter_at_line_offset(line_num, 0)
      end_iter   = @buffer.get_iter_at_line_offset(line_num+1, 0) # FIXME!
      @buffer.remove_all_tags(start_iter, end_iter)
      scopes.each do |scope|
        unless scope.start == scope.end or 
            (!scope.name and (scope.pattern and !scope.pattern.content_name))
          colour_scope(scope, false)
          if scope.pattern and scope.pattern.content_name
            colour_scope(scope, true)
          end
        end
        
      end
    end
    
    def colour_line(scope_tree, line_num, priority=1)
      #SyntaxLogger.debug "\n"
      buffer = @tab.buffer
      buffer.remove_all_tags(@tab.line_start(line_num),
                             @tab.line_end(line_num))
      colour_line1(scope_tree, line_num, priority)
    end
    
    def colour_line1(scope_tree, line_num, priority=1)
      buffer = @tab.buffer
      return if scope_tree.children.empty?
      if e=scope_tree.children.first.end and e.line >= line_num
        first_ix = 0
      else
        first_ix  = scope_tree.children.find_flip_index {|cs| !cs.end or cs.end.line >= line_num }
      end
      if scope_tree.children.last.start.line > line_num
        second_ix = -1
      else
        second_ix = scope_tree.children.find_flip_index {|cs| cs.start.line > line_num }
     end
      return unless first_ix
      second_ix = -1 unless second_ix
#       scope_tree.children.each do |scope|
      children_checked = scope_tree.children[first_ix..(second_ix-1)].length
#      Instrument(:colourer_children_checked, children_checked)
      count = 0
      for scope in scope_tree.children[first_ix..second_ix]
        extra_priority = 0
        if scope.on_line?(line_num) 
          count += 1
          unless scope.start == scope.end or 
              (!scope.name and (scope.pattern and !scope.pattern.content_name))# scope.children.empty?)
            sl = buffer.get_iter_at_line_offset(scope.start.line, 0)
            start_iter = buffer.get_iter_at_offset(sl.offset+minify(scope.start.offset))
            if scope.end
              el = buffer.get_iter_at_line_offset(scope.end.line, 0)
              end_iter   = buffer.get_iter_at_offset(el.offset+minify(scope.end.offset))
            else
              el = buffer.get_iter_at_line_offset(scope.start.line+1, 0)
              end_iter = el
              if el.offset == sl.offset
                end_iter = buffer.get_iter_at_offset(buffer.char_count)
              end
            end
            all_settings = @theme.settings_for_scope(scope)
            #SyntaxLogger.debug "  "*priority+"<"+scope.hierarchy_names.join("\n  "+"  "*priority)+">"
            #all_settings.each {|s| SyntaxLogger.debug "  "*(priority)+ s.inspect}
            if all_settings.empty?
              tag_reference = "default ("+priority.to_s+")"
              settings_hash = {:foreground => theme.global_settings['foreground']}
            else
              settings = all_settings[0]["settings"]
#               p all_settings
#               p settings
              tag_reference = all_settings[0]["scope"]+" ("+priority.to_s+")"
              settings_hash = Theme.textmate_settings_to_pango_options(settings)
            end
            unless tag = buffer.tag_table.lookup(tag_reference)
              tag = buffer.create_tag(tag_reference, settings_hash)
              tag.priority = priority
            end
#            SyntaxLogger.debug {"  "*priority + 
#              "tag:#{tag_reference}: (#{start_iter.line}, #{start_iter.line_offset})-"+
#              "(#{end_iter.line}, #{end_iter.line_offset})"}
            if tag
#              SyntaxLogger.debug {"  "*priority + "#{start_iter.offset}-#{end_iter.offset}"}
#              SyntaxLogger.debug {"  "*priority + tag.inspect}
              buffer.apply_tag(tag, start_iter, end_iter)
              extra_priority = 1
            end
          end
          colour_line1(scope, line_num, priority+extra_priority)
        end
      end
#      Instrument(:prop_children_on_line, count.to_f/children_checked)
 #               Instrument(:priority, priority)
    end
    

    def minify(offset)
      if offset < 200
        offset
      else
        200
      end
    end
  end
end
