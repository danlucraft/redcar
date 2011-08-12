
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
        @changed = true
        @path = path
      end
      
      def title
        File.basename(@path) + "/"
      end
      
      # Does the directory exist?
      def exists?
        @adapter.exists?(@path) && @adapter.directory?(@path)
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
        Node.create_from_path(@adapter, {:fullname => path})
      end
      
      # Turn the nodes into data.
      def to_data(nodes)
        nodes.map {|node| node.path }
      end
      
      def refresh_operation(tree)
        @adapter.refresh_operation(tree) do
          yield
        end
      end
      
      class Node
        include Redcar::Tree::Mirror::NodeMirror

        attr_reader :path, :adapter
        attr_accessor :type, :is_empty_directory

        def self.create_all_from_path(adapter, path)
          fs = adapter.fetch_contents(path)
          fs.reject! { |f| [".", ".."].include?(File.basename(f[:fullname])) }
          unless DirMirror.show_hidden_files?
            fs.reject! { |f| f[:type] == :file and Project::FileList.hide_file?(f[:fullname]) }
            fs.reject! { |f| f[:type] == :dir and Project::FileList.hide_directory? f[:fullname] }
          end
          fs.sort_by do |f|
            File.basename(f[:fullname]).downcase
          end.sort_by do |f|
            f[:type] == :dir ? -1 : 1
          end.map {|f| create_from_path(adapter, f) }
        end
        
        def self.create_from_path(adapter, f)
          if result = cache[f[:fullname]]
            result.type               = f[:type]
            result.is_empty_directory = f[:empty]
            result
          else
            cache[f[:fullname]] = Node.new(adapter, f[:fullname], f[:type], f[:empty])
          end
        end

        def self.cache
          @cache ||= {}
        end
        
        def initialize(adapter, path, type, is_empty_directory)
          @adapter            = adapter
          @path               = path
          @type               = type
          @is_empty_directory = is_empty_directory
        end
        
        def text
          File.basename(@path)
        end
        
        def icon
          case @type
          when :file
            key = text.split('.').last.split(//).first.downcase
            if key =~ /[b-z]/
              :"document_attribute_#{key}"
            elsif key == 'a'
              :document_attribute
            else
              :document
            end
          when :dir
            :blue_folder
          end
        end

        def leaf?
          file?
        end
        
        def file?
          @type == :file
        end
        
        def directory?
          @type == :dir
        end
        
        def parent_dir
          File.dirname(@path)
        end
        
        def directory
          directory? ? @path : File.dirname(@path)
        end
        
        def children
          if file? or @is_empty_directory
            []
          else
            Node.create_all_from_path(adapter, @path)
          end
        end

        def children?
          !file? and !@is_empty_directory
        end
        
        def tooltip_text
          File.basename(@path)
        end
        
        def inspect
          "#<Project::DirMirror::Node path=#{path}>"
        end
      end
    end
  end
end
