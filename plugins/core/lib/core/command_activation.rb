module Redcar
  module CommandActivation
    
    def norecord?
      @norecord
    end
    
    def pass?
      @pass
    end
    
    def active=(val)
      @sensitive_active = val
      #      p @name
#       puts "#{self}.active = #{val.inspect}"
      update_operative
    end
    
    def update_operative
      old = @operative
#       puts "update_operative: #{self.inspect}" if @key == "Ctrl+S"
#       puts "  #{!!active?}" if @key == "Ctrl+S"
#       puts "  #{!!in_range?}" if @key == "Ctrl+S"
      @operative = if active? and in_range?
        if self.ancestors[1].ancestors.include? Redcar::Command
          self.ancestors[1].operative?
        else
          true
        end
      else
        false
      end
#       puts "  com: #{self.inspect}: #{old.inspect} -> #{@operative.inspect}" if @key == "Ctrl+S"
      if old != @operative and @menu_item
#         p :updating_menu_sensitivity if @key == "Ctrl+S"
        Redcar::MenuDrawer.set_active(@menu_item, @operative)
      end
      child_commands.each(&:update_operative)
    end
    
    def update_menu_sensitivity
      Redcar::MenuDrawer.set_active(@menu_item, @operative)
    end
    
    def in_range=(val)
      old = @in_range
      #       p :in_range=
      #         p self
      #         p val
      @in_range = val
      update_operative
    end
    
    def nearest_range_ancestor
      #       puts "nearest_range_ancestor: #{self.to_s.split("::").last}, #{@range.to_s.split("::").last}"
      r = if @range
        self
      elsif self.ancestors[1..-1].include? Redcar::Command
        self.ancestors[1].nearest_range_ancestor
      else
        nil
      end
      #       if r
      #         p r
      #       else
      #         p "nil range"
      #       end
      r
    end
    
    def in_range?
      if nra = nearest_range_ancestor
        nra.get(:in_range)
      else
        #         p self
        #         p :global
        true # a command with no ranges set anywhere
        # in the hierarchy is a Window command
      end
    end
    
    def operative?
      @operative == nil ? active? : @operative
    end
    
    def correct_scope?(scope=nil)
      if @scope
        if !scope
          false
        else
          app = Gtk::Mate::Matcher.test_match(@scope, scope.hierarchy_names(true))
          if self.ancestors[1].ancestors.include? Redcar::EditTabCommand
            app and self.ancestors[1].correct_scope?(scope)
          else
            app
          end
        end
      else
        if self.ancestors[1].ancestors.include? Redcar::EditTabCommand
          self.ancestors[1].correct_scope?(scope)
        else
          true
        end
      end
    end
    
    def executable?(tab=nil)
      scope = nil
      scope = tab.document.cursor_scope if tab and tab.class <= EditTab
      o = operative?
      s = correct_scope?(scope)
      #      e = (operative? and correct_scope?(scope))
      e = (o and s)
      e
    end
  end
end
