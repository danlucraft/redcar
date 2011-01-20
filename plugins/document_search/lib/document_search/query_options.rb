
module Redcar
  module DocumentSearch
    # Encapsulates options for search queries.
    class QueryOptions
      attr_accessor :query_type
      attr_accessor :match_case
      attr_accessor :wrap_around

      DEFAULT_QUERY_TYPE  = :query_plain
      DEFAULT_MATCH_CASE  = false
      DEFAULT_WRAP_AROUND = true

      # Initializes with default options.
      def initialize
        @query_type  = DEFAULT_QUERY_TYPE
        @match_case  = DEFAULT_MATCH_CASE
        @wrap_around = DEFAULT_WRAP_AROUND
      end

      ### UTILITY ###

      # Maps a search type combo box value to the corresponding search type symbol.
      def self.query_type_to_symbol(query_type_text)
        case query_type_text
        when "Plain"
          :query_plain
        when "Regex"
          :query_regex
        when "Glob"
          :query_glob
        else
          raise "Invalid query type: #{query_type_text}"
        end
      end

      # Maps a search type symbol to a text value for the search type combo box.
      def self.query_type_to_text(query_type_symbol)
        case query_type_symbol
        when :query_plain
          'Plain'
        when :query_regex
          'Regex'
        when :query_glob
          'Glob'
        else
          raise "Invalid query type symbol: #{query_type_symbol}"
        end
      end
    end
  end
end