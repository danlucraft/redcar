
module Redcar
  class DeletePathInProjectCommand < Redcar::Command
    def initialize(path)
      @path = path
    end
    
    def execute
      if pt = ProjectTab.instance
        pt.delete_path(@path)
      end
    end
  end
end
