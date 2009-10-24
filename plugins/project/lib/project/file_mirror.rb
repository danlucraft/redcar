
require "digest/sha1"

module Redcar
  class Project
    # Represents a local file. Implements the EditView::Mirror interface so it
    # can be used as a mirror for a Redcar::Document. This is how files are 
    # loaded in Redcar. EditView contains a Document which contains a Mirror
    # which reflects a file.
    class FileMirror
      include Redcar::EditView::Mirror
      
      def initialize(path)
        @path = path
      end
      
      def read
        contents = load_contents
        @hash = Digest::SHA1.hexdigest(contents)
        contents
      end
      
      def exists?
        File.exists?(@path)
      end
      
      def changed?
        @hash != Digest::SHA1.hexdigest(load_contents)
      end
      
      def commit(contents)
        save_contents(contents)
        @hash = Digest::SHA1.hexdigest(contents)
      end
      
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
