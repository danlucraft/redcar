require 'java'

module Redcar
  module SyntaxCheck
    class JavaScript < Checker
      supported_grammars "JavaScript", "JavaScript (Rails)", "jQuery (JavaScript)"

      def jslint_path
        File.join(File.dirname(__FILE__),'../../vendor/jslint.js')
      end

      def rhino_path
        File.join(File.dirname(__FILE__),'../../vendor/js.jar')
      end

      def check(*args)
        path    = manifest_path(doc)
        name    = File.basename(path)
        text    = doc.get_all_text
        Thread.new do
          begin
            output = `java -cp #{rhino_path} org.mozilla.javascript.tools.shell.Main #{jslint_path} #{path}`
            output.each_line do |line|
              if line =~ /Lint at line (\d+) character (\d+): (.*)/
                SyntaxCheck::Error.new(doc, $1.to_i-1, $3).annotate
              end
            end
          rescue Object => e
            SyntaxCheck.message(
            "An error occurred while parsing #{name}: #{e.message}",:error)
          end
        end
      end
    end
  end
end
