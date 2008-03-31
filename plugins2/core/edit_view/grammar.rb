

$spare_name = "aaaa"

class Redcar::EditView
  class Pattern
    attr_accessor :name, :captures, :grammar, :hint, :match, :scope_name
    attr_reader :folding_start_marker, :folding_stop_marker
    
    def initialize(hash, grammar)
      @grammar = grammar
      @name = hash["name"]
      @scope_name = @name
      @content_name = hash["content_name"] 
      @folding_start_marker = hash["foldingStartMarker"]
      @folding_stop_marker = hash["foldingStopMarker"]
      @captures = hash["captures"] || {}
      @captures.each do |key, value|
        @captures[key] = value['name']
      end
      @hint = 0
    end
    
    def to_scope
      new_scope = Scope.create3(self, self.grammar)
    end
    
    def possible_patterns
      self.grammar.possible_patterns(self)
    end
  end
  
  class SinglePattern < Pattern
    def initialize(hash, grammar)
      super(hash, grammar)
      
      @match = Oniguruma::ORegexp.new(hash["match"], 
                 :options => Oniguruma::OPTION_CAPTURE_GROUP)
    end
    
    def patterns
      []
    end
    
    def inspect
      "<singlepattern:#{self.name}, matches:#{@match.inspect}>"
    end
    
    def content_name
      nil
    end
  end
  
  class DoublePattern < Pattern
    attr_accessor(:begin, :end, :patterns, :content_name, :begin_captures, 
                  :end_captures, :captures)
    
    def initialize(hash, grammar)
      super(hash, grammar)
      @begin = Oniguruma::ORegexp.new(hash["begin"]||"", 
                 :options => Oniguruma::OPTION_CAPTURE_GROUP)
      @end   = hash["end"] || hash["endif"] # FIXME : what is "endif"??
      count = 0
      @patterns = (hash["patterns"]||[]).collect do |this_hash|
        pn = self.grammar.pattern_from_hash(this_hash)
        unless pn.is_a? IncludePattern
          pn.hint = count
          count += 1
        end
        pn
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
      "<doublepattern:#{self.name}, begin:#{@begin.inspect}, end:#{@end.inspect}>"
    end
    
    def match
      @begin
    end
  end
  
  class IncludePattern
    attr_accessor :type, :value, :grammar
    def initialize(hash, grammar)
      @grammar = grammar
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
    def self.load_grammars
      unless Redcar::EditView.cache_dir
        raise "called Grammar.load_grammars without a cache_dir"
      end
      cache_dir = Redcar::EditView.cache_dir
      if File.exist?(cache_dir + "grammars.dump")
        str = File.read(cache_dir + "grammars.dump")
        @grammars = Marshal.load(str)
        @grammars_by_extension ||= {}
        @grammars.each do |name, gr|
          (gr.file_types||[]).each do |ext|
            @grammars_by_extension["."+ext] = @grammars[name]
          end
        end
      else
        @grammars ||= {}
        @grammars_by_extension ||= {}
        plists = []
        if @grammars.keys.empty?
          Dir.glob(Redcar::EditView.bundles_dir + "*/Syntaxes/*").each do |file|
            if %w(.plist .tmLanguage).include? File.extname(file)
              begin
                puts "loading #{file}"
                xml = IO.readlines(file).join
                plist = Redcar::Plist.plist_from_xml(xml)
                gr = plist[0]
                plists << plist
                @grammars[gr['name']] = Grammar.new(plist[0])
                (gr['fileTypes'] || []).each do |ext|
                  @grammars_by_extension["."+ext] = @grammars[gr['name']]
                end
              rescue => e
                puts "failed to load syntax: #{file}"
                puts e.message
              end
            end
          end
          self.cache_grammars
        end
      end
    end
    
    def self.grammar(options)
      if options[:name]
        @grammars[options[:name]]
      elsif options[:extension]
        @grammars_by_extension[options[:extension]]
      elsif options[:first_line]
        @grammars.each do |name, gr|
          if gr.first_line_match and options[:first_line] =~ gr.first_line_match
            return gr 
          end
        end
        nil
      elsif options[:scope]
        @grammars.each do |_, gr|
          if gr.scope_name == options[:scope]
            return gr
          end
        end
        nil
      end
    end
    
    def self.grammars
      load_grammars unless @grammars
      @grammars
    end
    
    def self.names
      load_grammars unless @grammars
      @grammars.keys
    end
    
    def self.cache_grammars
      if @grammars
        str = Marshal.dump(@grammars)
        File.open(Redcar::EditView.cache_dir + "grammars.dump", "w") do |f|
          f.puts str
        end
      end
    end

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
      if @grammar["firstLineMatch"]
        @first_line_match = Oniguruma::ORegexp.new(@grammar["firstLineMatch"], 
                              :options => Oniguruma::OPTION_CAPTURE_GROUP)
      end
      @folding_start_marker = @grammar["foldingStartMarker"]
      @folding_stop_marker = @grammar["foldingStopMarker"]
      @patterns = (grammar["patterns"]||[]).collect do |hash|
        pn = pattern_from_hash(hash)
        pn
      end
      @repository = {}
      (grammar["repository"]||[]).each do |name, pattern_hash|
        if pattern_hash.keys.include? "begin" or
            pattern_hash.keys.include? "match"
          @repository[name] = pattern_from_hash(pattern_hash)
        elsif pattern_hash.keys.include? "patterns"
          @repository[name] = pattern_hash["patterns"].map do |ph|
            pattern_from_hash(ph)
          end
        end
      end
      collate_patterns
      @pattern_lookup.each_value {|p| p.grammar = self if p.is_a? Pattern}
    end
    
    def content_name
      nil
    end
    
    def inspect
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
    
    def possible_patterns(pattern=nil)
      #        SyntaxLogger.debug { "possible patterns for: #{pattern.inspect}" }
      pattern = self unless pattern
      @possible_patterns ||= {}
      r = @possible_patterns[pattern]
      return r if r
      if pattern
        if pattern.to_s == self.scope_name.to_s or
            pattern.to_s == self.to_s
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
            when :base
              self.patterns
            when :repository
              pn.grammar.pattern_lookup[pn.value.to_s]
            when :scope
              p = pn.grammar.pattern_lookup[pn.value.to_s]
              unless p
                p = Redcar::EditView::Grammar.grammar(:scope => pn.value)
              end
              p.patterns if p
            end
          end
        else
          pn
        end
      end.compact.flatten
    end

    def pattern_from_hash(hash)
      # FIXME: what is "endif"?
      ks = hash.keys
      if ks.include? "begin"  and (ks.include? "end" or ks.include? "endif")
        DoublePattern.new(hash, self)
      elsif ks.include? "match"
        SinglePattern.new(hash, self)
      elsif ks.include? "include"
        IncludePattern.new(hash, self)
      else
        raise ArgumentError, "unknown Pattern type #{hash.inspect}"
      end
    end
  end
end

