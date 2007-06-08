
$spare_name = "aaaa"

module Redcar
  module Syntax
    class Pattern
      attr_accessor :name, :captures, :grammar, :hint, :match
      
      def initialize(hash)
        unless hash["name"] or hash["contentName"]
          hash["name"] = $spare_name.clone
          $spare_name = $spare_name.succ
        end
        @name = hash["name"] || hash["contentName"]
        @captures = hash["captures"] || {}
        @captures.each do |key, value|
          @captures[key] = value['name']
        end
        @hint = 0
      end
      
      def to_scope
        new_scope = Scope.create3(self, self.grammar)
      end
    end
    
    class SinglePattern < Pattern
      def initialize(hash)
        super(hash)
        
        @match = Regexp.new(hash["match"])
      end
      
      def patterns
        []
      end
      
      def inspect
        "<singlepattern:#{self.name}, matches:#{Regexp.new(@match).inspect}>"
      end
    end
    
    class DoublePattern < Pattern
      attr_accessor(:begin, :end, :patterns, :content_name, :begin_captures, 
                    :end_captures, :captures)
      
      def initialize(hash)
        super(hash)
        @begin = Regexp.new(hash["begin"])
        @match = @begin
        @end   = hash["end"] || hash["endif"] # FIXME : what is "endif"??
        @patterns = (hash["patterns"]||[]).collect do |this_hash|
          Grammar.pattern_from_hash(this_hash)
        end
        @content_name = hash["contentName"]
        @begin_captures = hash["beginCaptures"] || {}
        @begin_captures.each do |key, value|
          @begin_captures[key] = value['name']
        end
        @end_captures = hash["endCaptures"] || {}
        @end_captures.each do |key, value|
          @end_captures[key] = value['name']
        end
        @captures.each do |key, value|
          @begin_captures[key] = value
          @end_captures[key] = value
        end
      end
      
      def inspect
        "<doublepattern:#{self.name}, begin:#{Regexp.new(@begin).inspect}, end:#{@end}>"
      end
    end
    
    class IncludePattern
      attr_accessor :type, :value
      def initialize(hash)
        case hash["include"][0..0]
        when '#'
          @type = :repository
          @value = hash["include"][1..-1]
        when '$'
          if hash["include"] == "$self"
            @type = :self
          elsif hash["include"] == "$base"
            @type = :base
          else
            raise ArgumentError, "unknown $ include: '#{hash['include']}'"
          end
        else
          @type = :scope
          @value = hash["include"]
        end
      end
      
      def name
        @value
      end
    end

    class Grammar
      attr_accessor(:name,
                    :comment,
                    :scope_name, 
                    :file_types,
                    :first_line_match,
                    :folding_start_marker,
                    :folding_stop_marker,
                    :patterns,
                    :repository,
                    :pattern_lookup)
      
      def initialize(grammar)
        @grammar = grammar
        @name = @grammar["name"]
        @comment = @grammar["comment"]
        @scope_name = @grammar["scopeName"]
        @file_types = @grammar["fileTypes"]
        @first_line_match = @grammar["firstLineMatch"]
        @folding_start_marker = @grammar["foldingStartMarker"]
        @folding_stop_marker = @grammar["foldingStopMarker"]
        @patterns = (grammar["patterns"]||[]).collect do |hash|
          Grammar.pattern_from_hash(hash)
        end
        @repository = {}
        (grammar["repository"]||[]).each do |name, pattern_hash|
          if pattern_hash.keys.include? "begin" or
              pattern_hash.keys.include? "match"
            @repository[name] = Grammar.pattern_from_hash(pattern_hash)
          elsif pattern_hash.keys.include? "patterns"
            @repository[name] = pattern_hash["patterns"].map do |ph|
              Grammar.pattern_from_hash(ph)
            end
          end
        end
        
        collate_patterns
        @pattern_lookup.each_value {|p| p.grammar = self if p.is_a? Pattern}
      end
      
      def inspect
#        "<grammar:#{@name}, scope:#{@scope_name}, patterns:[#{@patterns.map{|p| (p.respond_to?(:name) ? p.name : "[noname]")}.join(", ")}]>"
        "<grammar:#{@name}, scope:#{@scope_name}>"
      end
      
      def collate_patterns
        @pattern_lookup = {}
        @patterns.each do |pattern|
          unless pattern.is_a? IncludePattern
            @pattern_lookup[pattern.name.to_s] = pattern
            collate_patterns1(pattern)
          end
        end
        @repository.each do |name, pattern|
          unless pattern.is_a? IncludePattern
            @pattern_lookup[name] = pattern
            unless pattern.is_a? Array
              @pattern_lookup[pattern.name] = pattern
            end
            collate_patterns1(pattern)
          end
        end
      end
      
      def collate_patterns1(pattern)
        if pattern.is_a? Array # can happen when a repository value is a list of patterns
          patterns = pattern.collect do |p| 
            unless p.is_a? IncludePattern
              p.patterns
            end
          end.flatten.select {|p| p}
        else
          patterns = pattern.patterns
        end
        patterns.each do |p|
          unless p.is_a? IncludePattern
            @pattern_lookup[p.name.to_s] = p
            collate_patterns1(p)
          end
        end
      end
      
      def pattern(name)
        @pattern_lookup[name.to_s]
      end
      
      def clear_possible_patterns
        @possible_patterns = nil
      end
      
      def possible_patterns(pattern)
        @possible_patterns ||= {}
        r = @possible_patterns[pattern]
        return r if r
        if pattern
          if pattern.to_s == self.scope_name.to_s
            poss_patterns = self.patterns
            pattern = self
          else
            if pattern.is_a? String
              pattern = pattern(pattern)
            end
            poss_patterns = pattern.patterns
          end
        else
          poss_patterns = self.patterns
          pattern = self
        end
        already_included = []
        r = expand_possible_patterns(poss_patterns, already_included)
        while r.any? {|pn| pn.is_a? IncludePattern }
          r = expand_possible_patterns(r, already_included)
        end
        @possible_patterns[pattern] = r.compact.sort_by{|p| -p.hint}
      end
      
      def expand_possible_patterns(pps, already_included)
        pps.map do |pn|
          if pn.is_a? IncludePattern
            if already_included.include? [pn.type, pn.value]
              nil
            else
              already_included << [pn.type, pn.value]
              case pn.type
              when :self
                self.patterns
              when :repository
                @pattern_lookup[pn.value.to_s]
              when :Scope
                @pattern_lookup[pn.value.to_s]
              end
            end
          else
            pn
          end
        end.compact.flatten
      end
      
    end
    
    class << Grammar
      def pattern_from_hash(hash)
        # FIXME: what is "endif"?
        if hash["begin"] and (hash["end"] or hash["endif"])
          DoublePattern.new(hash)
        elsif hash["match"]
          SinglePattern.new(hash)
        elsif hash["include"]
          IncludePattern.new(hash)
        else
          raise ArgumentError, "unknown Pattern type #{hash.inspect}"
        end
      end
    end
  end
end

