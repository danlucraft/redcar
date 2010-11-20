module DocumentSearch
  class ReplaceCommand < Redcar::DocumentCommand
    attr_reader :query, :replace

    def initialize(query, replace, search_method)
      @replace = replace
      @query   = send(search_method, query)
    end

    # An instance of a search type method: Regular expression
    def regex_search_query(query)
      /#{query}/
    end

    # An instance of a search type method: Plain text search
    def plain_search_query(query)
      regex_search_query(Regexp.escape(query))
    end

    # An instance of a search type method: Glob text search
    # Converts a glob pattern (* or ?) into a regex pattern
    def glob_search_query(query)
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
      regex_search_query(new_query)
    end
  end
end