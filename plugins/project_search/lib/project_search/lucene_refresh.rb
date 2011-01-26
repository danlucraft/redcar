
class ProjectSearch
  
  class LuceneRefresh < Redcar::Task
    def initialize(project)
      @project     = project
    end
    
    def description
      "#{@project.path}: refresh index"
    end
    
    def execute
      return if @project.remote?
      unless index = ProjectSearch.indexes[@project.path]
        index = ProjectSearch::LuceneIndex.new(@project)
        ProjectSearch.indexes[@project.path] = index
      end
      index.update
    end
  end
end