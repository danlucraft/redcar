
module Redcar
  class Project
    class DirMirror
      class << self
        attr_accessor :show_hidden_files
        
        def show_hidden_files?
          show_hidden_files
        end
      end
        
      include Redcar::Tree::Mirror
      attr_reader :path, :adapter
      
      # @param [String] a path to a directory
      def initialize(path, adapter=Adapters::Local.new)
        @adapter = adapter
        @adapter.path = path
        
        @path = @adapter.real_path
        @changed = true
      end
      
      def title
        File.basename(@path) + "/"
      end
      
      # Does the directory exist?
      def exists?
        @adapter.exist? && @adapter.directory?
      end
      
      # Have the toplevel nodes changed?
      #
      # @return [Boolean]
      def changed?
        @changed
      end
      
      # Drag and drop is allowed in Dir trees
      def drag_and_drop?
        true
      end
      
      # The files and directories in the top of the directory.
      def top
        @changed = false
        Node.create_all_from_path(@adapter, @path)
      end
      
      # We specify a :file data type to take advantage of OS integration.
      def data_type
        :file
      end
      
      # Return the Node for this path.
      #
      # @return [Node]
      def from_data(path)
        Node.create_from_path(@adapter, path)
      end
      
      # Turn the nodes into data.
      def to_data(nodes)
        nodes.map {|node| node.path }
      end
      
      class Node
        include Redcar::Tree::Mirror::NodeMirror

        attr_reader :path, :adapter

        def self.create_all_from_path(adapter, path)
          fs = adapter.fetch_contents(path)
          fs = fs.reject {|f| [".", ".."].include?(File.basename(f))}
          unless DirMirror.show_hidden_files?
            fs = fs.reject {|f| File.basename(f) =~ /^\./ }
          end
          fs.sort_by do |fn|
            File.basename(fn).downcase
          end.sort_by do |path|
            adapter.directory?(path) ? -1 : 1
          end.map {|fn| create_from_path(adapter, fn) }
        end
        
        def self.create_from_path(adapter, path)
          cache[path] ||= Node.new(adapter, path)
        end
        
        def self.cache
          @cache ||= {}
        end
        
        def initialize(adapter, path)
          @adapter = adapter
          @path = path
          
          @children = [] if adapter.lazy?
        end
        
        def text
          File.basename(@path)
        end
        
        def icon
          if @adapter.file?(@path)
            :file
          elsif @adapter.directory?(@path)
            :directory
          end
        end
        
        def leaf?
          file?
        end
        
        def file?
          @adapter.file?(@path)
        end
        
        def directory?
          @adapter.directory?(@path)
        end
        
        def parent_dir
          File.dirname(@path)
        end
        
        def directory
          directory? ? @path : File.dirname(@path)
        end
        
        def calculate_children
          raise "Called calculate_children for non-lazy adapter: #{adapter}" unless adapter.lazy?
          @children = Node.create_all_from_path(adapter, path)
        end
        
        def children
          if @adapter.lazy?
            @children
          else
            Node.create_all_from_path(adapter, path)
          end
        end
        
        def tooltip_text
          File.basename(@path)
        end
      end
    end
  end
end
