module Redcar
  module DocumentSearch
    # Encapsulates options for search queries.
    class QueryOptions
      attr_accessor :is_regex
      attr_accessor :match_case
      attr_accessor :wrap_around

      DEFAULT_IS_REGEX  = false
      DEFAULT_MATCH_CASE  = false
      DEFAULT_WRAP_AROUND = true

      # Initializes with default options.
      def initialize
        @is_regex = DEFAULT_IS_REGEX
        @match_case  = DEFAULT_MATCH_CASE
        @wrap_around = DEFAULT_WRAP_AROUND
      end
    end
  end
end