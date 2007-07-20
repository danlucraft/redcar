
module Redcar
  class TextTab
    #keymap "super s", :scope_tooltip
    #keymap "super-shift S", :select_scope
    #keymap "control-super s", :print_scope_tree
    #keymap "alt-super s", :reparse_tab
    
    attr_accessor :scope_tree, :parser
    
    def sourceview
      @textview
    end
    
    def reparse_tab
      @textview.colour
      #debug_puts @textview.scope_tree.pretty
    end
    
    def print_scope_tree
      puts @textview.scope_tree.pretty
    end
    
    def scope_tooltip
      scope = scope_at_cursor
      puts "scope_at_cursor: #{scope.inspect}"
      inner = scope.pattern and scope.pattern.content_name and
        (cursor_offset >= scope.open_end.offset and 
         (!scope.close_start or cursor_offset < scope.close_start.offset))
      tooltip_at_cursor(scope.hierarchy_names(inner).join("\n"))
    end
    
    def current_scope
      if selected?
        x, y = selection_bounds
        xi = iter(x)
        yi = iter(y)
        scope = Syntax::Scope.common_ancestor(
            @scope_tree.scope_at(TextLoc.new(xi.line, xi.line_offset)),
            @scope_tree.scope_at(TextLoc.new(yi.line, yi.line_offset))
          )
      else
        scope = scope_at_cursor
      end
    end
    
    def current_scope_text
      scope = current_scope
      if scope
        end_iter = iter(scope.end)
        unless scope.end
          end_iter = iter(end_mark)
        end
        self.buffer.get_slice(iter(scope.start), end_iter)
      end
    end
    
    def select_scope
      scope = current_scope
      if scope
        end_iter = iter(scope.end)
        unless scope.end
          end_iter = iter(end_mark)
        end
        select(iter(scope.start), end_iter)
      end
    end
    
    def scope_at_cursor
      if @textview.scope_tree
        scope = @textview.scope_tree.scope_at(TextLoc.new(cursor_line, cursor_line_offset))
      end
    end
  end
end

sourceview_keymap = Redcar.Keymap.new("Text Editor")
sourceview_keymap.push_before(Redcar.SyntaxSourceView)
