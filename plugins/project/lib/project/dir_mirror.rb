
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
      include LocalFilesystem
      
      attr_reader :path
      
      # @param [String] a path to a directory
      def initialize(path)
        @changed = true
        @path = path
      end
      
      def title
        File.basename(@path) + "/"
      end
      
      # Does the directory exist?
      def exists?
        fs.exists?(@path) && fs.directory?(@path)
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
        Node.create_all_from_path(@path)
      end
      
      # We specify a :file data type to take advantage of OS integration.
      def data_type
        :file
      end
      
      # Return the Node for this path.
      #
      # @return [Node]
      def from_data(path)
        Node.create_from_path(:fullname => path)
      end
      
      # Turn the nodes into data.
      def to_data(nodes)
        nodes.map {|node| node.path }
      end
      
      class Node
        include Redcar::Tree::Mirror::NodeMirror
        extend LocalFilesystem

        attr_reader :path
        attr_accessor :type, :is_empty_directory

        def self.create_all_from_path(path)
          list = fs.fetch_contents(path)
          list.reject! { |f| [".", ".."].include?(File.basename(f[:fullname])) }
          unless DirMirror.show_hidden_files?
            list.reject! { |f| f[:type] == :file and Project::FileList.hide_file?(f[:fullname]) }
            list.reject! { |f| f[:type] == :dir and Project::FileList.hide_directory? f[:fullname] }
          end
          list.sort_by do |f|
            File.basename(f[:fullname]).downcase
          end.sort_by do |f|
            f[:type] == :dir ? -1 : 1
          end.map {|f| create_from_path(f) }
        end
        
        def self.create_from_path(f)
          if result = cache[f[:fullname]]
            result.type               = f[:type]
            result.is_empty_directory = f[:empty]
            result
          else
            cache[f[:fullname]] = Node.new(f[:fullname], f[:type], f[:empty])
          end
        end

        def self.cache
          @cache ||= {}
        end
        
        def initialize(path, type, is_empty_directory)
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
            Node.create_all_from_path(@path)
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
