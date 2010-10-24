require 'java'
require 'ruby_syntax_error'

module Redcar
  module SyntaxCheck
    class Ruby < Checker
      supported_grammars "Ruby", "Ruby on Rails"

      def check(*args)
        path    = manifest_path(doc)
        runtime = org.jruby.Ruby.global_runtime
        io      = java.io.FileInputStream.new(java.io.File.new(path))
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
