
class ProjectSearch
  class WordSearch
    attr_reader :query_string, :context_size
    
    def initialize(project, query_string, match_case, context_size)
      @project      = project
      @query_string = query_string
      @match_case   = !!match_case
      @context_size      = context_size
    end
    
    def match_case?
      @match_case
    end
    
    def matching_line?(line)
      line =~ regex
    end
    
    def regex
      @regex ||= begin
        regexp_text = Regexp.escape(@query_string)
        match_case? ? /#{regexp_text}/ : /#{regexp_text}/i
      end
    end
    
    def results
      []
    end
  end
end

