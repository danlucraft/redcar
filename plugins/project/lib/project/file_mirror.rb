
require "digest/sha1"

module Redcar
  class Project
    # Represents a local file. Implements the EditView::Mirror interface so it
    # can be used as a mirror for a Redcar::Document. This is how files are 
    # loaded in Redcar. EditView contains a Document which contains a Mirror
    # which reflects a file.
    class FileMirror
      include Redcar::Document::Mirror
      
      attr_reader :path
      
      # @param [String] a path to a file
      def initialize(path)
        @path = path
      end
      
      # Load the contents of the file from disk
      #
      # @return [String]
      def read
        return "" unless exists?
        contents = load_contents
        @hash = Digest::SHA1.hexdigest(contents)
        contents
      end
      
      # Does the file exist?
      #
      # @return [Boolean]
      def exists?
        File.exists?(@path)
      end
      
      # Has the file changed since the last time it was read or commited?
      # If it has never been read then this is true by default.
      #
      # @return [Boolean]
      def changed?
        @hash != Digest::SHA1.hexdigest(load_contents)
      end
      
      # Save new file contents.
      #
      # @param [String] new contents
      # @return [unspecified]
      def commit(contents)
        save_contents(contents)
        @hash = Digest::SHA1.hexdigest(contents)
      end
      
      # The filename.
      #
      # @return [String]
      def title
        @path.split("/").last
      end
      
      private
      
      def load_contents
        File.read(@path)
      end
      
      def save_contents(contents)
        File.open(@path, "w") {|f| f.print contents }
      end
    end
  end
end
