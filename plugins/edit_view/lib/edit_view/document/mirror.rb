
module Redcar
  class Document
    # Abstract interface. A Mirror allows an EditView contents to reflect 
    # some other resource. They have methods for loading the contents from the 
    # resource and commiting changes.
    #
    # Events: changed
    module Mirror
      include Redcar::Observable
      
      # Return the title of the resource. (e.g. the filename)
      def title
        raise "not implemented"
      end
      
      # Return the contents of the resource reflected by this mirror. 
      # (E.g. the contents of the file)
      def read
        raise "not implemented"
      end

      # Does the resource still exist or not? (E.g. does the file exist?)
      def exists?
        raise "not implemented"
      end
      
      # Has the resource changed since the last time either `read` or `commit` 
      # were was called? (E.g. has the file changed since the last time its 
      # contents were loaded)
      def changed?
        raise "not implemented"
      end
      
      # Replace the contents of the resource with `contents`. (E.g. save the
      # new contents of the file.)
      def commit(contents)
        raise "not implemented"
      end
    end
  end
end