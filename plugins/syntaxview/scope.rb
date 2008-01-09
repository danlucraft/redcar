
$spare_name = "aaaa"

$imp = :ruby

module Redcar
  module Syntax
    class ScopeException < Exception; end;
    class OverlappingScopeException < ScopeException; end;
    
    class Scope
      class << self
        def specificity(scope_name)
          scope_name.split(".").length
        end
        
        # use this method to compare ruby and C implementations.
        def c_diff(name, rbv, cv,data)
          if rbv != cv
            puts "'#{name}' C version differs. rb: #{rbv.inspect}, c:#{cv.inspect}, data:#{data.inspect}"
          end
          rbv != cv
        end
        
      end
      
      include Enumerable
      
      attr_accessor(:pattern, 
                    :grammar, 
                    :open_matchdata,
                    :close_matchdata,
                    :closing_regexp,
                    :capture)
      
      def self.create3(pattern, grammar)
        obj = self.allocate
        obj.pattern = pattern
        obj.grammar = grammar
        obj.open_end = nil
        obj.close_start = nil
        obj
      end
      
      def self.create2(start_loc, end_loc)
        obj = self.allocate
        obj.start = start_loc
        obj.end = end_loc
        obj.open_end = nil
        obj.close_start = nil
        obj
      end
      
      def create(name, pattern, grammar, start_loc, end_loc, parent, 
                 open_start, open_end, close_start, close_end, open_matchdata,
                 close_matchdata)
        allocate
        self.name           = name
        self.pattern        = pattern
        self.grammar        = grammar
        self.start          = start
        self.end            = end_loc
        self.closing_regexp = nil
        self.open_end       = open_end
        self.close_start    = close_start
        @open_matchdata     = open_matchdata
        @close_matchdata    = close_matchdata
      end
      
      def initialize2(options={})
        self.name           = options[:name]
        self.pattern        = options[:pattern]
        self.grammar        = options[:grammar]
        self.start          = options[:start]
        self.end            = options[:end]
        self.closing_regexp = options[:closing_regexp]
        self.open_end       = options[:open_end]
        self.close_start    = options[:close_start]
        @open_matchdata     = options[:open_matchdata]
        @close_matchdata    = options[:close_matchdata]
      end
      
      def each_child
        children.each {|c| yield c}
      end
      
      def start=(loc)
        if loc
          set_start(loc.line, loc.offset)
        else
          set_start(-1, -1)
        end
      end
      
      def end=(loc)
        if loc
          set_end(loc.line, loc.offset)
        else
          set_end(-1, -1)
        end
      end
      
      def open_start
        self.start if @open_matchdata
      end
      
      def close_end
        self.end if @close_matchdata
      end
      
      def open_end=(loc)
        if loc
          set_open_end(loc.line, loc.offset)
        else
          set_open_end(-1, -1)
        end
      end
      
      def close_start=(loc)
        if loc
          set_close_start(loc.line, loc.offset)
        else
          set_close_start(-1, -1)
        end
      end
      
      def name
        if name = get_name
          name
        else
          self.name = self.pattern.scope_name
        end
      end
      
      def name=(newname)
        set_name(newname) if newname
      end
      
      def priority
        @priority ||= if parent
                        parent.priority + 1
                      else
                        1
                      end
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
        return false unless self_same
        children_same = self.children.length == other.children.length
        return false unless children_same
        self.children.zip(other.children) do |c1, c2| 
          return false unless c1.identical?(c2)
        end
        true
      end
        
      def copy
        new_self = Scope.new({})
        new_self.name    = self.name
        new_self.grammar = self.grammar
        new_self.pattern = self.pattern
        new_self.start   = self.start.copy
        new_self.end     = self.end.copy
        new_self.open_end    = self.open_end.copy
        new_self.close_start = self.close_start.copy
        new_self.open_matchdata  = self.open_matchdata
        new_self.close_matchdata = self.close_matchdata
        new_self.closing_regexp  = self.closing_regexp
        self.each_child do |child|
          new_self.add_child child.copy
        end
        new_self
      end

      # Is this scope a descendent of scope other?
      def child_of?(other)
        parent == other or (parent and parent.child_of?(other))
      end
      
      # Return the names of all scopes in the hierarchy above this scope. Inner 
      # is true or false depending on whether you want to include this scopes
      # 'inner' scope (content_name scope).
      def hierarchy_names(inner=true)
        if parent
          next_inner = (parent.open_end and 
                        self.start >= parent.open_end and 
                        (!self.end or !parent.close_start or 
                         self.end < parent.close_start))
          names = parent.hierarchy_names(next_inner)
        else
          names = []
        end
        names << self.name if self.name
        if self.pattern and self.pattern.content_name and inner
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
        "<scope(#{self.object_id*-1%1000}):"+(self.name||"" rescue "noname")+" "+cname+" #{startstr}#{endstr} #{hanging}>"
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
      
      def detach_from_parent
        self.parent.delete_child(self)
      end

      # Shifts all scopes after offset in the given line 
      # by the given amount.
      def shift_chars(line, amount, offset)
        if self.start.line == line 
          if self.start.offset > offset
            self.start = TextLoc(self.start.line,
                                 self.start.offset + amount)
          end
          if self.open_end and self.open_end.offset > offset
            self.open_end = TextLoc(self.open_end.line,
                                    self.open_end.offset + amount)
          end
        end
        if self.end and self.end.line == line
          if self.end.offset > offset
            self.end = TextLoc(self.end.line,
                               self.end.offset + amount)
            if self.close_start
              self.close_start = TextLoc(self.close_start.line,
                                         self.close_start.offset + amount)
            end
          end
        end
        children.each do |cs| 
          cs.shift_chars(line, amount, offset)
        end
      end
      
      def shift_after(line, amount)
        if self.start.line >= line
          self.start = TextLoc(self.start.line + amount, self.start.offset)
          if self.open_start
            self.open_end = TextLoc(self.open_end.line + amount,
                                    self.open_end.offset)
          end
        end
        if self.end and self.end.line >= line
          self.end = TextLoc(self.end.line + amount, self.end.offset)
          if self.close_start
            self.close_start = TextLoc(self.close_start.line + amount,
                                       self.close_start.offset)
          end
        end
        
        children.each do |cs|
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

      def rb_scope_at(textloc)
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
              first_ix = children.find_flip_index do |cs|
                !cs.end or cs.end >= textloc
              end
              if first_ix
                second_ix = children.find_flip_index do |cs|
                  cs.start > textloc
                end
                second_ix = children.length-1 unless second_ix
                children[first_ix..second_ix].each do |cs|
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
      
#       def remove_children_that_overlap(new_scope)
#         each_child do |child|
#           if child.overlaps?(new_scope) and 
#               child != new_scope
#             delete_child(child)
#           end
#         end
#       end
      
      def first_child_after(loc)
        # this is the obvious way:
        # @children.find {|cs| cs.start >= loc}
        
        # this is a faster way (see vendor/binary_enum):
        children.find_flip {|cs| cs.start >= loc}
      end
      
      def each(&block)
        block.call(self)
        children.each do |cs| 
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
      
      def root
        if parent
          parent.root
        else
          self
        end
      end
    end
  end
end

