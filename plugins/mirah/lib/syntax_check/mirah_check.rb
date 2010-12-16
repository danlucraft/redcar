require 'java'

module Redcar
  module SyntaxCheck
    class MirahCheck < Checker
      supported_grammars "Mirah"

      @@first_use = true

      def check(*args)
        # lets not load the mirah-parser.jar until we really need it
        if @@first_use          
          require 'my_error_handler'
          @@first_use = false
        end
      
        path = manifest_path(doc)
        
        parser = MirahParser.new
        parser.filename = path
        # If you want to get warnings
        handler = MyErrorHandler.new
        parser.errorHandler = handler
        
        begin
          parser.parse(IO.read(path))
        rescue
          m = $!.message
          error = m.split(" (").first
          if info = m.match(/line: ([0-9]+), char: ([0-9]+)\)/)
            SyntaxCheck::Error.new(doc, info[1].to_i-1, error).annotate
          end
        end
        
        handler.problems.each { |problem|
          if info = problem.match(/line: ([0-9]+), char: ([0-9]+)\)/)
            SyntaxCheck::Error.new(doc, info[1].to_i-1, problem.split(" (").first).annotate
          end
        }
      end
    end
  end
end
