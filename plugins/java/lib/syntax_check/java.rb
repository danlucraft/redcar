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
                SyntaxCheck::Error.new(doc, $1.to_i - 1, $2).annotate
              end
            end
          end
        rescue Object => e
          SyntaxCheck.message(
          "An error occurred while parsing #{name}: #{e.message}", :error)
        end
        class_files = File.join(File.dirname(path),"*.class")
        junk  = Dir.glob(class_files)
        junk.each {|f| FileUtils.rm_rf(f) }
      end
    end
  end
end