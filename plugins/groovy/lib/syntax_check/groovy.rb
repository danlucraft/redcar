require 'java'

module Redcar
  module SyntaxCheck
    class Groovy < Checker
      supported_grammars "Groovy", "Easyb"

      def initialize(document)
        super
        unless @loaded
          require File.join(Redcar.asset_dir,"groovy-all")
          import 'groovy.lang.GroovyShell'
          import 'org.codehaus.groovy.control.CompilationFailedException'
          @loaded = true
        end
      end

      def check(*args)
        path    = manifest_path(doc)
        name    = File.basename(path)
        shell   = GroovyShell.new
        text    = doc.get_all_text
        io      = java.io.File.new(path)
        begin
          shell.parse(io)
        rescue CompilationFailedException => e
          create_syntax_error(doc, e.message, name).annotate
        end
      end

      def create_syntax_error(doc, message, name)
        message  =~ /#{Regexp.escape(name)}: (\d+):(.*)/
        line     = $1.to_i - 1
        message  = $2
        SyntaxCheck::Error.new(doc, line, message)
      end
    end
  end
end
