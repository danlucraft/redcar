
module Redcar
  class Project
    class DirMirror
      include Redcar::Tree::Mirror
      attr_reader :path
      
      # @param [String] a path to a directory
      def initialize(path)
        @path = File.expand_path(path)
        @changed = true
      end
      
      # Does the directory exist?
      def exists?
        File.exist?(@path)
      end
      
      # Have the toplevel nodes changed?
      #
      # @return [Boolean]
      def changed?
        @changed
      end
      
      # Get the top-level nodes
      #
      # @return [Array<Node>]
      def top
        @changed = false
        Node.create_all_from_path(@path)
      end
      
      class Node
        def self.create_all_from_path(path)
          Dir[path + "/*"].sort_by {|fn| File.basename(fn).downcase }.map {|fn| create_from_path(fn) }
        end
        
        def self.create_from_path(path)
          cache[path] ||= Node.new(path)
        end
        
        def self.cache
          @cache ||= {}
        end
        
        include Redcar::Tree::Mirror::NodeMirror
        
        attr_reader :path
        
        def initialize(path)
          @path = path
        end
        
        def text
          File.basename(@path)
        end
        
        def icon
          if File.file?(@path)
            :file
          elsif File.directory?(@path)
            :directory
          end
        end
        
        def leaf?
          File.file?(@path)
        end
        
        def children
          Node.create_all_from_path(@path)
        end
      end
    end
  end
end
