
$spare_name = "aaaa"

module Redcar
  module Syntax
    class ScopeException < Exception; end;
    class OverlappingScopeException < ScopeException; end;
    
    class Scope
      class << self
        def specificity(scope_name)
          scope_name.split(".").length
        end
      end
      
      include DebugPrinter
      include Enumerable
      
      attr_accessor(:children, 
                    :pattern, 
                    :grammar, 
                    :start, 
                    :end, 
                    :open_start,
                    :open_end,
                    :open_matchdata,
                    :close_start,
                    :close_end,
                    :close_matchdata,
                    :parent,
                    :name,
                    :closing_regexp,
                    :capture)
      
      def self.create3(pattern, grammar)
        obj = self.allocate
        obj.pattern = pattern
        obj.grammar = grammar
        obj.children = []
        obj
      end
      
      def self.create2(start_loc, end_loc)
        obj = self.allocate
        obj.start = start_loc
        obj.end = end_loc
        obj.children = []
        obj
      end
      
      def create(name, pattern, grammar, start_loc, end_loc, parent, 
                 open_start, open_end, close_start, close_end, open_matchdata,
                 close_matchdata)
        allocate
        @name               = name
        self.pattern        = pattern
        self.grammar        = grammar
        self.start          = start
        self.end            = end_loc
        self.parent         = parent
        self.closing_regexp = nil
        @open_start         = open_start
        @open_end           = open_end
        @close_start        = close_start
        @close_end          = close_end
        @open_matchdata     = open_matchdata
        @close_matchdata    = close_matchdata
        @children = []
      end
      
      def initialize(options={})
        @name               = options[:name]
        self.pattern        = options[:pattern]
        self.grammar        = options[:grammar]
        self.start          = options[:start]
        self.end            = options[:end]
        self.parent         = options[:parent]
        self.closing_regexp = options[:closing_regexp]
        @open_start         = options[:open_start]
        @open_end           = options[:open_end]
        @close_start        = options[:close_start]
        @close_end          = options[:close_end]
        @open_matchdata     = options[:open_matchdata]
        @close_matchdata    = options[:close_matchdata]
        @children = []
      end
      
      def overlaps?(other)
       # (self.start >= other.start and (!other.end or (self.start < other.end))) or
       #  (self.end and (self.end >= other.start and (!other.end or (self.end <= other.end))))
       (self.start >= other.start and (!other.end or (self.start < other.end))) or
        (self.end and (self.end > other.start and (!other.end or (self.end <= other.end))))
      end
      
      # Sees if the the scope is the same as the other scope, modulo their children
      # and THEIR CLOSING MARKERS.
      def surface_identical_modulo_ending?(other)
        self_same = (other.name  == self.name and
                     other.grammar == self.grammar and
                     other.pattern == self.pattern and
                     other.start   == self.start and
                     other.open_start  == self.open_start and
                     other.open_end    == self.open_end and
                     other.open_matchdata.to_s  == self.open_matchdata.to_s)
      end
      
      def surface_identical?(other)
        self_same = (other.name  == self.name and
                     other.grammar == self.grammar and
                     other.pattern == self.pattern and
                     other.start   == self.start and
                     other.end     == self.end and
                     other.open_start  == self.open_start and
                     other.open_end    == self.open_end and
                     other.close_start == self.close_start and
                     other.close_end   == self.close_end and
                     other.open_matchdata.to_s  == self.open_matchdata.to_s and
                     other.close_matchdata.to_s == self.close_matchdata.to_s and
                     other.closing_regexp.to_s  == self.closing_regexp.to_s)
      end
      
      def identical?(other)
        self_same = (other.name  == self.name and
                     other.grammar == self.grammar and
                     other.pattern == self.pattern and
                     other.start   == self.start and
                     other.end     == self.end and
                     other.open_start  == self.open_start and
                     other.open_end    == self.open_end and
                     other.close_start == self.close_start and
                     other.close_end   == self.close_end and
                     other.open_matchdata.to_s  == self.open_matchdata.to_s and
                     other.close_matchdata.to_s == self.close_matchdata.to_s and
                     other.closing_regexp.to_s  == self.closing_regexp.to_s)
        debug_puts "(#{self.inspect} == #{other.inspect}) == #{self_same}"
        unless self_same
          debug_puts "name: #{other.name}  == #{self.name} "
          debug_puts "open_start.inspect: #{other.open_start.inspect}  == #{self.open_start.inspect} "
          debug_puts "open_end.inspect: #{other.open_end.inspect}  == #{self.open_end.inspect} "
          debug_puts "grammar: #{other.grammar}  == #{self.grammar} "
          debug_puts "pattern.inspect: #{other.pattern.inspect}  == #{self.pattern.inspect} "
          debug_puts "start: #{other.start.inspect}  == #{self.start.inspect} "
          debug_puts "end: #{other.end.inspect}  == #{self.end.inspect} "
          debug_puts "close_end: #{other.close_end.inspect}  == #{self.close_end.inspect} "
          debug_puts "close_matchdata.to_s: #{other.close_matchdata.to_s.inspect}  == #{self.close_matchdata.to_s.inspect} "
          debug_puts "open_matchdata.to_s.inspect: #{other.open_matchdata.to_s.inspect}  == #{self.open_matchdata.to_s.inspect} "
          debug_puts "closing_regexp.to_s.inspect: #{other.closing_regexp.to_s.inspect}  == #{self.closing_regexp.to_s.inspect} "
        end
        return false unless self_same

        children_same = self.children.length == other.children.length
        return false unless children_same
        self.children.zip(other.children) do |c1, c2| 
          return false unless c1.identical?(c2)
        end
        true
      end
        
      def copy
        new_self = Scope.new
        new_self.name    = self.name
        new_self.grammar = self.grammar
        new_self.pattern = self.pattern
        new_self.start   = self.start.copy
        new_self.end     = self.end.copy
        new_self.open_start  = self.open_start.copy
        new_self.open_end    = self.open_end.copy
        new_self.close_start = self.close_start.copy
        new_self.close_end   = self.close_end.copy
        new_self.open_matchdata  = self.open_matchdata
        new_self.close_matchdata = self.close_matchdata
        new_self.closing_regexp  = self.closing_regexp
        
        new_self.children = self.children.collect{|c| c.copy}
        new_self
      end

      # Is this scope active on line num?
      def on_line?(num)
        self.start.line <= num and 
          (!self.end or (self.end and self.end.line >= num))
      end
      
      # Clear all scopes that are not active on line num.
      def clear_not_on_line(num)
        @children = @children.select do |cs|
          keep = cs.on_line?(num)
          cs.clear_not_on_line(num)
          keep
        end
        nil
      end

      # Is this scope a descendent of scope other?
      def child_of?(other)
        @parent == other or (@parent and @parent.child_of?(other))
      end
      
      # Return the names of all scopes in the hierarchy above this scope.
      def hierarchy_names
        if @parent
          names = @parent.hierarchy_names
        else
          names = []
        end
        names << self.name if self.name
        if self.pattern and self.pattern.content_name
          names << self.pattern.content_name
        end
        names
      end
      
      # Returns the nearest common ancestor of scopes s1 and s2 or 
      # nil if none.
      def self.common_ancestor(s1, s2)
        an, di = self.common_ancestor1(s1, s2)
        an
      end
      
      def self.common_ancestor1(s1, s2, distance=0) # :nodoc:
        if s1 == s2
          return [s1, distance]
        else
          if s1.parent
            c1, d1 = self.common_ancestor1(s1.parent, s2, distance+1)
          else
            c1 = nil
          end
          if s2.parent
            c2, d2 = self.common_ancestor1(s1, s2.parent, distance+1)
          else
            c2 = nil
          end
          if c1 and not c2
            return c1, d1
          elsif c2 and not c1
            return c2, d2
          elsif c1 and c2
            if d1 <= d2
              return c1, d1
            else
              return c2, d2
            end
          else
            return nil, distance
          end
        end
      end
      
      def pretty(indent=0)
        str = ""
        str += " "*indent + self.inspect+"\n"
        children.each do |cs|
          str += cs.pretty(indent+2)
        end
        str
      end
      
      def captures
        @open_matchdata.captures
      end
      
      def name
        @name ||= self.pattern.scope_name
      end
      
      def to_s
        self.name
      end
      
      def inspect
        if self.pattern.is_a? SinglePattern
          hanging = ""
        else
          if self.end
            hanging = " closed"
          else
            hanging = " hanging"
          end
        end
        startstr = "(#{start.line},#{start.offset})-"
        if self.end
          endstr = "(#{self.end.line},#{self.end.offset})"
        else
          endstr = "?"
        end
        if self.pattern
          cname = ""+self.pattern.content_name.to_s
        else
          cname = ""
        end
        "<scope(#{self.object_id*-1%1000}):"+(self.name||"noname")+" "+cname+" #{startstr}#{endstr} #{hanging}>"
      end
      
      def sort_children
        children.sort_by {|cs| cs.start}
      end
      
      def assert_does_not_overlap(scope)
        if (scope.start < self.start) or 
            (scope.end and self.end and scope.end > self.end)
          raise OverlappingScopeException, "child overlaps edges of scope"
        end
        children.each do |cs| 
          if (cs.end and cs.start < scope.start and scope.start < cs.end) or
              (cs.end and scope.end and cs.start < scope.end and scope.end < cs.end) 
            raise OverlappingScopeException, "scope has overlapping children"
          end
        end
      end
      
      def add_child(child)
        unless child.is_a? Scope
          raise ScopeException, "trying to add non-scope as child of scope"
        end
        #Instrument(:add_child, 1)
        # if it goes on the end:
        if @children.empty? or (@children.last.end and child.start >= @children.last.end)
          @children << child
          #Instrument(:add_child_at_end?, 1)
        else
          #Instrument(:add_child_at_end?, 0)
          # the old slow way:
          # @children << child
          # @children = @children.sort_by do |c|
          #   [c.start.line, c.start.offset]
          # end
          
          # the new faster way (see vendor/binary_enum):
          ix = @children.find_flip_index {|cs| cs.start > child.start }
          unless ix
            ix = @children.length
          end
          @children.insert(ix, child)
        end
        child.parent = self
      end

      def clear_after(textloc)
        if self.end and self.end > textloc
          self.end = nil
          self.close_start = nil
          self.close_end = nil
        end
        
        @children = @children.select do |cs|
          keep = (cs.start < textloc)
          if keep
            cs.clear_after(textloc)
          end
          keep
        end
      end
      
      # Clear all scopes that start between TextLocs from and to, and
      # re-open scopes that ended between these lines.
      def clear_between(from, to)
        if self.end and self.end >= from and self.end < to
          self.end = nil
          self.close_start = nil
          self.close_end = nil
        end
        @children = @children.select do |cs|
          discard = (cs.start >= from and cs.start < to) or
            (cs.end and cs.end >= from and cs.end < to)
          unless discard
            cs.clear_between(from, to)
          end
          !discard
        end
      end
      
      # Clear all scopes that start between lines from and to inclusive, and
      # re-open scopes that ended between these lines.
      def clear_between_lines(from, to)
        range = from..to
        if self.end and range.include? self.end.line
          self.end = nil
          self.close_start = nil
          self.close_end = nil
        end
        @children = @children.select do |cs|
          keep = (!range.include? cs.start.line)
          if keep
            cs.clear_between_lines(from, to)
          end
          keep
        end
      end
      
      # Shifts all scopes after offset in the given line 
      # by the given amount.
      def shift_chars(line, amount, offset)
#        if self.parent # don't do this for the top scope in the page
          if self.start.line == line 
            if self.start.offset > offset
              self.start.offset += amount
              if self.open_start
                self.open_start.offset += amount
              end
            end
            if self.open_end and self.open_end.offset > offset
              self.open_end.offset += amount
            end
          end
          if self.end and self.end.line == line
            if self.end.offset > offset
              self.end.offset += amount
              if self.close_start
                self.close_start.offset += amount
              end
            end
            if self.close_end and self.close_end.offset > offset
              self.close_end.offset += amount
            end
          end
#         if self.start == self.end
#           self.detach_from_parent
#         end
 #       end
        @children.each {|cs| cs.shift_chars(line, amount, offset)}
      end
      
      def shift_after(line, amount)
        if self.start.line >= line
          self.start.line += amount
          if self.open_start
            self.open_start.line += amount
            self.open_end.line += amount
          end
        end
        if self.end and self.end.line >= line
          self.end.line   += amount
          if self.close_start
            self.close_start.line += amount
            self.close_end.line   += amount
          end
        end
        
        @children.each do |cs|
          cs.shift_after(line, amount)
        end
      end
      
      def size
        size = 0
        children.each do |cs|
          size += 1 + cs.size
        end
        size
      end

      def delete_any_on_line_not_in(line_num, scopes)
        @children = @children.reject do |cs|
          if cs.start.line == line_num and !scopes.include?(cs)
            debug_puts "deleting: #{cs.inspect}"
            true
          else
            false
          end
        end
      end
      
      # Returns the active scope at TextLoc textloc.
      def scope_at(textloc)
        if self.start <= textloc or !self.parent
          if ((self.end==nil) or (self.end > textloc))
            # children has a tendency to be very long for 1 scope in each document,
            # so do a simple check that looks to see if it is the last child we need,
            # which it often is when we are parsing an entire tab.
            if children.last and children.last.end and children.last.end < textloc
              return self
            else
              # old slow way:
              # children.each do |cs|
              #   if r = cs.scope_at(textloc)
              #     return r
              #   end
              # end
              
              # new fast way (see vendor/binary_enum):
              first_ix = @children.find_flip_index do |cs|
                !cs.end or cs.end >= textloc
              end
              if first_ix
                second_ix = @children.find_flip_index do |cs|
                  cs.start > textloc
                end
                second_ix = @children.length-1 unless second_ix
                @children[first_ix..second_ix].each do |cs|
                  if r = cs.scope_at(textloc)
                    return r
                  end
                end
                self
              else
                self
              end
            end
          else
            nil
          end
        else
          # My start is too late.
          nil
        end
      end
      
      def first_child_after(loc)
        # this is the obvious way:
        # @children.find {|cs| cs.start >= loc}
        
        # this is a faster way (see vendor/binary_enum):
        @children.find_flip {|cs| cs.start >= loc}
      end
      
      def each(&block)
        block.call(self)
        @children.each do |cs| 
          cs.each(&block)
        end
      end
      
      def scopes_closed_on_line(line_num, &block)
        # this is the obvious way:
        # self.each { |s| yield(s) if s.end and s.end.line == line_num }
        
#         # this is a faster way:
#         if self.end and self.end.line == line_num
#           yield self
#         end
#         self.children.each do |cs|
#           unless cs.start.line > line_num or
#               (cs.end and cs.end.line < line_num)
#             cs.scopes_closed_on_line(line_num, &block)
#           end
#         end
        
        # this is another faster way
        if self.end and self.end.line == line_num
          yield self
        end
        first_ix = self.children.find_flip_index {|cs| cs.end and cs.end.line >= line_num }
        if first_ix
          second_ix = self.children.find_flip_index {|cs| cs.start.line > line_num }
          second_ix = self.children.length-1 unless second_ix
          self.children[first_ix..second_ix].each do |cs|
            cs.scopes_closed_on_line(line_num, &block)
          end
        end
      end
      
      def detach_from_parent
        self.parent.children.delete(self)
      end
      
      def line_start(line_num)
        sc = scope_at(TextLoc.new(line_num, -1))
        while sc.start.line == line_num
          unless sc.parent
            return sc
          end
          sc = sc.parent
        end
        sc
      end
      
      def line_end(line_num)
        scope_at(TextLoc.new(line_num+1, -1))
      end
      
      def last_scope
        if children.empty?
          self
        else
          if self.end == nil
            self
          else
            children.last
          end
        end
      end
    end
  end
end

