
module Redcar
  class Mirah
    class MyErrorHandler
      include ErrorHandler

      def problem(m)
        (@problems||=[]) << m
      end

      def problems
        @problems || []
      end

      def warning(messages, positions)
        messages.length.times { |i|
          problem "Warning: #{messages[i]} #{positions[i]}"
        }
      end
    end
  end
end