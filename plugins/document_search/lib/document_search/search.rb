module DocumentSearch
  class Search
    # An instance of a search type method: Regular expression
    def self.regex_search_method(line, query, replace)
      re = /#{query}/
      if match_data = line.match(re)
        new_text = match_data.to_s.sub(re, replace)
        new_line = match_data.pre_match + new_text + match_data.post_match
        
        startoff = match_data.pre_match.length
        endoff   = startoff + new_text.length
          
        return new_line, startoff, endoff
      end
    end

    # An instance of a search type method: Plain text search
    def self.plain_search_method(line, query, replace)
      if i = line.index(query)
        startoff = i
        endoff   = i + query.length - 1
        line[startoff..endoff] = replace
        return line, startoff, startoff + replace.length
      end
    end
    
    # An instance of a search type method: Glob text search
    # Converts a glob pattern (* or ?) into a regex pattern
    def self.glob_search_method(line, query, replace)
      # convert the glob pattern to a regex pattern
      new_query = ""
      query.each_char do |c| 
        case c
        when "*"
          new_query << ".*"
        when "?"
          new_query << "."
        else          
          new_query << Regexp.escape(c)
        end
      end
      regex_search_method(line, new_query, replace)
    end
  end
end