
module Redcar
  class RenamePathInProjectCommand < Redcar::Command
    def initialize(path)
      @path = path
    end
    
    def execute
      if pt = ProjectTab.instance
        pt.rename_path(@path)
      end
    end
  end
end
