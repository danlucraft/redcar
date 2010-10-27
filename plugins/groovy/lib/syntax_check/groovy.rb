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
          rescue Object => e
            Redcar::Application::Dialog.message_box("Error loading groovy classpath file #{path}: #{e.message}")
          end
          parts = parts + part if part
        end
        parts
      end

      def create_shell
        config    = CompilerConfiguration.new
        if project = Redcar::Project::Manager.focussed_project
          classpath = classpath(project)
          config.setClasspathList(classpath) if classpath
        end
        GroovyShell.new(config)
      end
    end
  end
end
