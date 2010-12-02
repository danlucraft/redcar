
class ProjectSearch
  class Query
    attr_reader :query_string
    
    # Construct a 
    #
    #
    def initialize(project, query_string, regex, match_case, context)
      @project      = project
      @query_string = query_string
      @regex        = regex
      @match_case   = match_case
      @context      = context
    end
    
    def match_case?
      @match_case
    end
    
    def context
      @context
    end
    
    def regex?
      @regex
    end
  end
end