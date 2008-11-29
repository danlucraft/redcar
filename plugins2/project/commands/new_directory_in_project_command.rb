
module Redcar
  class NewDirectoryInProjectCommand < Redcar::Command
    def initialize(path)
      @path = path
    end
    
    def execute
      if pt = ProjectPlugin.tab
        pt.new_dir_at(@path)
      end
    end
  end
end
