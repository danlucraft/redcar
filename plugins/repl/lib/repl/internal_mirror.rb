
module Redcar
  class REPL
    class InternalMirror
      include Redcar::EditView::Mirror
      
      def read
        message + prompt
      end

      def exists?
        true
      end

      def changed?
      end

      def commit(contents)
      end

      def title
        "(internal)"
      end
      
      private
      
      def message
        "*** Redcar REPL\n\n"
      end
      
      def prompt
        ">> "
      end
    end
  end
end
