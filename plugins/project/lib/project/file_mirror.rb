
require "digest/sha1"

module Redcar
  class Project
    # Represents a local file. Implements the EditView::Mirror interface so it
    # can be used as a mirror for a Redcar::Document. This is how files are 
    # loaded in Redcar. EditView contains a Document which contains a Mirror
    # which reflects a file.
    class FileMirror
      include Redcar::Document::Mirror
      
      attr_reader :path, :adapter
      
      # @param [String] a path to a file
      def initialize(path, adapter=Adapters::Local.new)
        @path = path
        @adapter = adapter
      end
      
      # Load the contents of the file from disk
      #
      # @return [String]
      def read
        return "" unless exists?
        contents = load_contents
        @timestamp = @adapter.mtime(@path)
        contents
      end
      
      # Does the file exist?
      #
      # @return [Boolean]
      def exists?
        @adapter.exists?(@path)
      end
      
      # Has the file changed since the last time it was read or commited?
      # If it has never been read then this is true by default.
      #
      # @return [Boolean]
      def changed?
        begin
          !@timestamp or @timestamp < @adapter.mtime(@path)
        rescue Errno::ENOENT
          false
        end
      end
      
      def changed_since?(time)
        begin
          !@timestamp or (!time and changed?) or (time and time < File.mtime(@path))
        rescue Errno::ENOENT
          false
        end
      end
      
      # Save new file contents.
      #
      # @param [String] new contents
      # @return [unspecified]
      def commit(contents)
        save_contents(contents)
        @time = Time.now
      end
      
      # The filename.
      #
      # @return [String]
      def title
        @path.split(/\/|\\/).last
      end
      
      private
      
      def load_contents
        @adapter.load(@path)
      end
      
      def save_contents(contents)
        @adapter.save(@path, contents)
      end
    end
  end
end
