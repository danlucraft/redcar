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
          import 'org.codehaus.groovy.control.CompilerConfiguration'
          @loaded = true
        end
      end

      def check(*args)
        path    = manifest_path(doc)
        name    = File.basename(path)
        shell   = create_shell
        text    = doc.get_all_text
        io      = java.io.File.new(path)
        begin
          shell.parse(io)
        rescue CompilationFailedException => e
          create_syntax_error(doc, e.message, name).annotate
        rescue Object => e
          SyntaxCheck.message(
            "An error occurred while parsing #{name}: #{e.message}",:error)
        end
      end

      def create_syntax_error(doc, message, name)
        message  =~ /#{Regexp.escape(name)}: (\d+):(.*)/
        line     = $1.to_i - 1
        message  = $2
        SyntaxCheck::Error.new(doc, line, message)
      end

      def classpath_files(project)
        project.config_files("classpath.groovy")
      end

      def classpath(project)
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
              "An error occurred while loading groovy classpath file #{path}: #{e.message}",:error)
          end
        end
        parts
      end

      def create_shell
        config = CompilerConfiguration.new
        if project = Redcar::Project::Manager.focussed_project
          classpath = classpath(project)
          config.setClasspathList(classpath) if classpath and classpath.any?
        end
        shell = GroovyShell.new(config)
        shell.setProperty("out",nil)
        shell
      end
    end
  end
end
