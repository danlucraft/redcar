
module Redcar
  module SyntaxCheck
    class Mirah < Checker

        require File.join(File.dirname(__FILE__),'..','..','vendor','mirah-parser.jar')
        import 'mirah.impl.MirahParser'
        import 'jmeta.ErrorHandler'

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
end
