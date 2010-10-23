require 'java'
require 'ruby_syntax_error'

module Redcar
  module SyntaxCheck
    class Ruby < Checker

      module Java
        import 'java.io.File'
        import 'java.io.FileInputStream'
        import 'org.jruby.Ruby'
      end

      supported_grammars "Ruby", "Ruby on Rails"

      def check(*args)
        path = manifest_path(doc)
        runtime = Java::Ruby.global_runtime
        io = Java::FileInputStream.new(Java::File.new(path))
        begin
          runtime.parse_from_main(io, File.basename(path))
        rescue SyntaxError => e
          @error = e.exception.message
        end

        if @error
          RubySyntaxError.new(doc, :message => @error, :file => File.basename(path)).annotate
        end
      end
    end
  end
end
