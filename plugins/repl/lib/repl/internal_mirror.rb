
module Redcar
  class REPL
    class InternalMirror
      include Redcar::EditView::Mirror
      
      def read
        result, @result = @result, nil
        result
      end

      def exists?
        true
      end

      def changed?
        @result
      end

      def commit(contents)
        puts contents
        @result = eval(contents)
      end

      def title
        "(internal)"
      end
    end
  end
end
