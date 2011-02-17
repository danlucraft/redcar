
module Redcar
  class Project
    def search(query, options)
      options ||= {}
      
      strategy   = (options[:regex] || false) ? RegexSearch : WordSearch
      match_case = options[:match_case] || true
      context    = options[:context]    || 0
      
      strategy.new(ProjectSearch.indexes[self], query, match_case, context)
    end
  end
end