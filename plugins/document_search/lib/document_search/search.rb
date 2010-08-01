module DocumentSearch
  class Search
    # An instance of a search type method: Regular expression
    def self.regex_search_method(line, query, replace)
      if line =~ /#{query}/
        startoff = $`.length
        endoff   = (startoff + $&.length) - 1
        line[startoff..endoff] = replace
        return line, startoff, startoff + replace.length
      end
      return nil
    end

    # An instance of a search type method: Plain text search
    def self.plain_search_method(line, query, replace)
      i = line.index(query)
      if i
        startoff = i
        endoff   = i + query.length - 1
        line[startoff..endoff] = replace
        return line, startoff, startoff + replace.length
      end
      return nil
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