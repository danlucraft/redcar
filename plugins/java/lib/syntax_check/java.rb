require 'java'
require 'open3'
module Redcar
  module SyntaxCheck
    class Java < Checker
      supported_grammars "Java"

      def check(*args)
        path = manifest_path(doc)
        name = File.basename(path)
        temp = java.lang.System.getProperty('java.io.tmpdir')
        if t = Java.thread and t.alive? and t[:java]
          t.exit
          SyntaxCheck.remove_syntax_error_annotations(doc.edit_view)
        end
        Java.thread=Thread.new do
          Thread.current[:java] = true
          begin
            cmd = "javac -d #{temp}"
            if project = Project::Manager.focussed_project and
              cpath = classpath(project)
              cmd << " -cp \"#{cpath}\""
            end
            stdin,stdout,err = Open3.popen3("#{cmd} #{path}")
            err.each_line do |msg|
              if msg =~ /#{Regexp.escape(name)}:(\d+):(.*)/
                SyntaxCheck::Error.new(doc, $1.to_i - 1, $2).annotate
                sleep 1
              end
            end
          rescue Object => e
            SyntaxCheck.message(
            "An error occurred while parsing #{name}: #{e.message}", :error)
          end
        end
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
        composite = ""
        separator = java.lang.System.getProperty('path.separator')
        parts.each {|p| composite << p+separator}
        composite[0,composite.length-1] if composite.length > 0
        composite
      end

      private

      def self.thread
        @thread
      end

      def self.thread=(thread)
        @thread = thread
      end
    end
  end
end