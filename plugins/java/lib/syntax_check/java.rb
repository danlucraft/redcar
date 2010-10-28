require 'java'

module Redcar
  module SyntaxCheck
    class Java < Checker
      supported_grammars "Java"
      def check(*args)
        import 'javax.tools.ToolProvider'
        import 'java.io.ByteArrayOutputStream'
        
        path    = manifest_path(doc)
        name    = File.basename(path)
        shell   = ToolProvider.getSystemJavaCompiler
        errors  = ByteArrayOutputStream.new
        begin
          out = shell.run(nil,nil,errors,path)
          if out != 0
            message = java.lang.String.new(errors.toByteArray).to_s
            message.each_line do |msg|
              if msg =~ /#{Regexp.escape(name)}:(\d+):(.*)/
                create_syntax_error(doc, msg, name).annotate
              end
            end
          end
        rescue Object => e
          p e
        end
      end

      def create_syntax_error(doc, message, name)
        message  =~ /#{Regexp.escape(name)}:(\d+):(.*)/
        line     = $1.to_i - 1
        message  = $2
        SyntaxCheck::Error.new(doc, line, message)
      end
    end
  end
end