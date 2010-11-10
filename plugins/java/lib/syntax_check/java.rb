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
          if project = Project::Manager.focussed_project and
            cpath = classpath(project)
            p cpath
            out = shell.run(nil,nil,errors,path, "classpath=#cpath")
          else
            out = shell.run(nil,nil,errors,path)
          end
          if out != 0
            message = java.lang.String.new(errors.toByteArray).to_s
            message.each_line do |msg|
              if msg =~ /#{Regexp.escape(name)}:(\d+):(.*)/
                SyntaxCheck::Error.new(doc, $1.to_i - 1, $2).annotate
              end
            end
          end
        rescue java.lang.Exception => e
          p e.stackTrace
        # rescue Object => e
        #   SyntaxCheck.message(
        #   "An error occurred while parsing #{name}: #{e.message}", :error)
        end
        class_files = File.join(File.dirname(path),"*.class")
        junk  = Dir.glob(class_files)
        junk.each {|f| FileUtils.rm_f(f) }
      end

      def classpath_files(project)
        project.config_files("classpath.groovy")
      end

      def classpath(project)
        unless @loaded
          require File.join(Redcar.asset_dir,"groovy-all")
          import 'groovy.lang.GroovyShell'
          import 'org.codehaus.groovy.control.CompilationFailedException'
          import 'org.codehaus.groovy.control.CompilerConfiguration'
          @loaded = true
        end
        parts  = []
        shell  = GroovyShell.new
        files  = classpath_files(project)
        return unless files.any?
        files.each do |path|
          begin
            file  = java.io.File.new(path)
            part  = shell.run(file, [])
            parts += part if part
          rescue Object => e
            SyntaxCheck.message(
            "An error occurred while loading classpath file #{path}: #{e.message}",:error)
            end
          end
          build_classpath(parts)
      end

      def build_classpath(parts)
        p parts
        composite = ""
        parts.each {|p| composite << p+';'}
        composite[0,composite.length-1] if composite =~ /;$/
        composite
      end
    end
  end
end