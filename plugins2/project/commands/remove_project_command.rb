
module Redcar
  class RemoveProjectCommand < Command
    def initialize(path)
      @path = path
    end
  
    def execute
      if pt = ProjectPlugin.tab
        pt.remove_project(@path)
     end
    end
  end
end
