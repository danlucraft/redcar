
module Redcar
  class Mirah
    class SyntaxChecker < Redcar::SyntaxCheck::Checker
      supported_grammars "Mirah"

      def check(*args)
        Mirah.load_dependencies
        check_warnings = Mirah.storage['check_for_warnings']
        path = manifest_path(doc)

        parser = MirahParser.new
        parser.filename = path

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

        if check_warnings
          handler.problems.each do |problem|
            if info = problem.match(/line: ([0-9]+), char: ([0-9]+)\)/)
              SyntaxCheck::Warning.new(doc, info[1].to_i-1, problem.split(" (").first).annotate
            end
          end
        end
      end
    end
  end
end