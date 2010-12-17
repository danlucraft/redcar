require 'java'
module Redcar
  module SyntaxCheck
    class Mirah < Checker
      supported_grammars "Mirah"

       @@loaded = false

      def initialize(document)
        super
        # load mirah-parser.jar with the firs use
        unless @@loaded
          require 'syntax_check/my_error_handler'
          @@loaded = true
        end
      end

      def check(*args)
        path = manifest_path(doc)

        parser = MirahParser.new
        parser.filename = path
        # If you want to get warnings
        handler = MyErrorHandler.new
        parser.errorHandler = handler
        SyntaxCheck.remove_syntax_error_annotations(doc.edit_view)
        begin
          parser.parse(IO.read(path))
        rescue
          m = $!.message
          error = m.split(" (").first
          if info = m.match(/line: (\d+), char: (\d+)\)/)
            SyntaxCheck::Error.new(doc, (info[1].to_i-1), error, info[2].to_i-1).annotate
          end
        end

        handler.problems.each do |problem|
          if info = problem.match(/line: (\d+), char: (\d+)\)/)
            SyntaxCheck::Warning.new(doc, (info[1].to_i), problem.split(" (").first, info[2].to_i-1).annotate
          end
        end

      end
    end
  end
end
