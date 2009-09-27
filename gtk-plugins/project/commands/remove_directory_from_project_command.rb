
module Redcar
  class RemoveDirectoryFromProjectCommand < Command
    def initialize(path)
      @path = path
    end
  
    def execute
      if pt = ProjectTab.instance
        pt.remove_project(@path)
     end
    end
  end
end
