
module Redcar
  class Project
    class DirMirror
      
      # @param [String] a path to a directory
      def initialize(path)
        @path = File.expand_path(path)
      end
      
      # Does the directory exist?
      def exists?
        File.exist?(@path)
      end
    end
  end
end
