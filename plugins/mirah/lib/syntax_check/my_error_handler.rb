puts "LOADED"

module Redcar
  module SyntaxCheck
    class MirahCheck < Checker

      require 'mirah-parser.jar'
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

        def error(messages, positions)
          messages.length.times { |i|
            problem "Warning: #{messages[i]} #{positions[i]}"              
          }
        end
      end
    end
  end
end
