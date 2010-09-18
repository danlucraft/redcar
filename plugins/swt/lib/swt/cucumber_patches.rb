
module Cucumber
  module Ast
    class StepInvocation #:nodoc:# 
      class << self
        attr_accessor :wait_time
      end
      
      def invoke(step_mother, options)
        #block = Swt::RRunnable.new do
          find_step_match!(step_mother)
          unless @skip_invoke || options[:dry_run] || @exception || @step_collection.exception
            @skip_invoke = true
            begin
              @step_match.invoke(@multiline_arg)
              step_mother.after_step
              status!(:passed)
            rescue Pending => e
              failed(options, e, false)
              status!(:pending)
            rescue Undefined => e
              failed(options, e, false)
              status!(:undefined)
            rescue Exception => e
              failed(options, e, false)
              status!(:failed)
            end
          end
          #end
        
        #Redcar::ApplicationSWT.display.syncExec(block)
        #empty_block = Swt::RRunnable.new { }
        #Redcar::ApplicationSWT.display.syncExec(block)

        if ENV["SLOW_CUKES"]
          sleep ENV["SLOW_CUKES"].to_f
        end
        sleep(Cucumber::Ast::StepInvocation.wait_time || 0)
        Cucumber::Ast::StepInvocation.wait_time = nil
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
          files.map!    {|f| File.expand_path(f) }
          files.reject! {|f| !File.file?(f)}
          files.reject! {|f| File.extname(f) == '.feature' }
          files.reject! {|f| f =~ /^http/}
          files
        end
      end
    end
  end
end