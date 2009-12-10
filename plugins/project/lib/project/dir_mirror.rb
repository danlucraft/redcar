
module Redcar
  class Project
    class DirMirror
      include Redcar::TreeView::Mirror
      
      # @param [String] a path to a directory
      def initialize(path)
        @path = File.expand_path(path)
      end
      
      # Does the directory exist?
      def exists?
        File.exist?(@path)
      end
      
      # Have the toplevel nodes changed?
      def changed?
        true
      end
      
      def top
        Dir[@path + "/*"].map {|fn| Node.new(fn)}
      end
      
      class Node
        include Redcar::TreeView::Mirror::NodeMirror
        
        def initialize(path)
          @path = path
        end
        
        def text
          File.basename(@path)
        end
        
        def leaf?
          File.file?(@path)
        end
      end
    end
  end
end
