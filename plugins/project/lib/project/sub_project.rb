
module Redcar
  class Project
    class SubProject < Project

      def initialize(project_path, path)
        super(path)
        @project = project_path
      end

      def config_files(glob)
        file_glob = File.join("#{@project}/.redcar", glob)
        super + Dir[file_glob]
      end
    end
  end
end