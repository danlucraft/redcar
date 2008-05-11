
$spare_name = "aaaa"

$imp = :ruby

class Redcar::EditView
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
          puts "'#{name}' C version differs. rb: #{rbv.inspect}," +
            " c:#{cv.inspect}, data:#{data.inspect}"
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
                  :capture, 
                  :capture_num,
                  :capture_end)
    
    def self.create3(pattern, grammar)
      obj = self.allocate
      obj.pattern = pattern
      obj.name    = pattern.scope_name
      obj.grammar = grammar
      obj.cinit
      obj
    end
    
    def self.create2
      obj = self.allocate
      obj.cinit
      obj
    end
    
    def create(name, pattern, grammar, parent, open_matchdata,
               close_matchdata)
      allocate
      self.pattern        = pattern
      self.name           = self.pattern ? self.pattern.scope_name : nil
      self.grammar        = grammar
      self.closing_regexp = nil
      @open_matchdata     = open_matchdata
      @close_matchdata    = close_matchdata
      obj.cinit
    end
    
    def initialize2(options)
      self.pattern        = options[:pattern]
      self.name           = (self.pattern ? self.pattern.scope_name : nil)
      self.grammar        = options[:grammar]
      self.closing_regexp = options[:closing_regexp]
      @open_matchdata     = options[:open_matchdata]
      @close_matchdata    = options[:close_matchdata]
    end
    
    def start
      TextLoc.new(self.start_line, self.start_line_offset)
    end
    
    def end
      TextLoc.new(self.end_line, self.end_line_offset)
    end
      
    def open_end
      if self.inner_start_line
        TextLoc.new(self.inner_start_line, self.inner_start_line_offset)
      end
    end
      
    def close_start
      if self.inner_end_line
        TextLoc.new(self.inner_end_line, self.inner_end_line_offset)
      end
    end
    
    def each_child
      children.each {|c| yield c}
    end
    
    def name
      if this_name = get_name
        this_name
      else
        self.name = self.pattern.scope_name
      end
    end
    
    def name=(newname)
      set_name(newname) if newname
    end
    
    def scope_id
      @scope_id ||= rand(1000000)
    end
    
#     def priority
#       @priority ||= if parent
#                       parent.priority + 1
#                     else
#                       1
#                     end
#     end
    
    # Sees if the the scope is the same as the other scope, modulo their children
    # and THEIR CLOSING MARKERS.
    def surface_identical_modulo_ending?(other)
      self_same = (other.name  == self.name and
                   other.grammar == self.grammar and
                   other.pattern == self.pattern and
                   other.start   == self.start and
                   other.open_end    == self.open_end and
                   other.open_matchdata.to_s  == self.open_matchdata.to_s)
    end
    
    def surface_identical?(other)
      self_same = (other.name  == self.name and
                   other.grammar == self.grammar and
                   other.pattern == self.pattern and
                   other.start   == self.start and
                   other.end     == self.end and
                   other.open_end    == self.open_end and
                   other.close_start == self.close_start and
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
                   other.open_end    == self.open_end and
                   other.close_start == self.close_start and
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
    
    # Is this scope a descendent of scope other?
    def child_of?(other)
      parent == other or (parent and parent.child_of?(other))
    end
    
    def ancestral_child_of(other)
      if self.parent == nil
        nil
      elsif self.parent == other
        self
      else
        self.parent.ancestral_child_of(other)
      end
    end
    
    # Return the names of all scopes in the hierarchy above this scope. Inner 
    # is true or false depending on whether you want to include this scopes
    # 'inner' scope (content_name scope).
    def rb_hierarchy_names(inner=true, i=0)
      if parent
        next_inner = (parent.open_end and 
                      self.start >= parent.open_end and 
                      (!self.end or !parent.close_start or 
                       self.end < parent.close_start))
        names = parent.hierarchy_names(next_inner, i+1)
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
    
    def pretty2(indent=0)
      str = ""
      str += " "*indent + "+ " + self.inspect2+"\n"
      children.each do |cs|
        str += cs.pretty2(indent+2)
      end
      str
    end
    
    def pretty3(indent=0)
      str = ""
      str += " "*indent + "+ " + self.inspect3+"\n"
      children.each do |cs|
        str += cs.pretty3(indent+2)
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
        if self.get_open
          hanging = " open"
        else
          hanging = " closed"
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
    
    def inspect2
      if self.pattern.is_a? SinglePattern
        hanging = ""
      else
        if self.get_open
          hanging = " open"
        else
          hanging = " closed"
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
      (self.name||"" rescue "noname")+" "+cname+" #{startstr}#{endstr} #{hanging}>"
    end
    
    def inspectwithbg
      if self.pattern.is_a? SinglePattern
        hanging = " #{self.bg_color.inspect}, #{self.nearest_bg_color.inspect}"
      else
        if self.end and self.end.valid?
          hanging = " closed #{self.bg_color.inspect}, #{self.nearest_bg_color.inspect}"
        else
          hanging = " hanging #{self.bg_color.inspect}, #{self.nearest_bg_color.inspect}"
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
      (self.name||"" rescue "noname")+" "+cname+" #{startstr}#{endstr} #{hanging}>"
    end
    
    def get_mark_string(mark)
      buf = mark.buffer
      iter = buf.get_iter_at_mark(mark)
      "#{iter.line},#{iter.line_offset}"
    end
    
    def inspect3
      if self.pattern.is_a? SinglePattern
        hanging = ""
      else
        if self.end and self.end.valid?
          hanging = " closed"
        else
          hanging = " hanging"
        end
      end
      startstr = "(#{start.line},#{start.offset})"
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
      (self.name||"" rescue "noname")+" "+cname+" #{startstr}#{endstr} #{hanging}>"
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

    def size
      size = 0
      children.each do |cs|
        size += 1 + cs.size
      end
      size
    end
    
    def each(&block)
      block.call(self)
      children.each do |cs| 
        cs.each(&block)
      end
    end
    
#     def scopes_closed_on_line(line_num, &block)
#       # this is the obvious way:
#       # self.each { |s| yield(s) if s.end and s.end.line == line_num }
      
#       #         # this is a faster way:
#       #         if self.end and self.end.line == line_num
#       #           yield self
#       #         end
#       #         self.children.each do |cs|
#       #           unless cs.start.line > line_num or
#       #               (cs.end and cs.end.line < line_num)
#       #             cs.scopes_closed_on_line(line_num, &block)
#       #           end
#       #         end
      
#       # this is another faster way
#       if self.end and self.end.line == line_num
#         yield self
#       end
#       first_ix = self.children.find_flip_index {|cs| cs.end and cs.end.line >= line_num }
#       if first_ix
#         second_ix = self.children.find_flip_index {|cs| cs.start.line > line_num }
#         second_ix = self.children.length-1 unless second_ix
#         self.children[first_ix..second_ix].each do |cs|
#           cs.scopes_closed_on_line(line_num, &block)
#         end
#       end
#     end
    
    def descendants_on_line(line_num)
      ds = []
      children.each do |child|
        if child.on_line?(line_num)
          ds << child
          ds += child.descendants_on_line(line_num)
        end
      end
      ds
    end
    
#     def line_start(line_num)
#       sc = scope_at(TextLoc.new(line_num, -1))
#       while sc.start.line == line_num
#         unless sc.parent
#           return sc
#         end
#         sc = sc.parent
#       end
#       sc
#     end
    
#     def line_end(line_num)
#       scope_at(TextLoc.new(line_num+1, -1))
#     end
    
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
    
    # Latest scope of tree not including self.
    def last_scope1
      if children.empty?
        nil
      else
        children.last
      end
    end
    
    def root?
      !parent.to_bool
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

