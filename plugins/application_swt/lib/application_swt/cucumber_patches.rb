
module Cucumber
  
  module Ast
    class TreeWalker
      def visit_steps(steps)
        broadcast(steps) do
          block = Swt::RRunnable.new do
            steps.accept(self)
          end
          Redcar::ApplicationSWT.display.syncExec(block)
        end
      end

      def visit_step(step)
        broadcast(step) do
          block = Swt::RRunnable.new do
            step.accept(self)
          end
          Redcar::ApplicationSWT.display.syncExec(block)
        end
      end
    end
  end
  
  module RbSupport
    class RbLanguage
      def require_support_files(path)
        @step_mother.load_code_files(Cli::Configuration.code_files_in_paths([path]))
      end
    end
    
    module RbDsl
      def RequireSupportFiles(path)
        RbDsl.require_support_files(path)
      end
      
      class << self
        def require_support_files(path)
          @rb_language.require_support_files(path)
        end
      end
    end
  end
  
  module Cli
    class Configuration
      def all_files_to_load
        requires = @options[:require].empty? ? require_dirs : @options[:require]
        files = Configuration.code_files_in_paths(requires)
        remove_excluded_files_from(files)
        files
      end

      class << self
        def code_files_in_paths(requires)
          files = requires.map do |path|
            path = path.gsub(/\\/, '/') # In case we're on windows. Globs don't work with backslashes.
            path = path.gsub(/\/$/, '') # Strip trailing slash.
            File.directory?(path) ? Dir["#{path}/**/*"] : path
          end.flatten.uniq
          files.reject! {|f| !File.file?(f)}
          files.reject! {|f| File.extname(f) == '.feature' }
          files.reject! {|f| f =~ /^http/}
          files
        end
      end
    end
  end
end