
module Redcar
  class ShellCommand
    include Redcar::Sensitive
    include Redcar::CommandActivation
    
    attr_accessor(:tm_uuid, :bundle, :shell_script, :name, :key, 
                  :range, :scope, :input_type, :fallback_input_type, :output_type,
                  :menu, :menu_item)

    def initialize(bundle)
      @bundle = bundle
    end
    
    def range=(val)
      @range = val
      Range.register_command(val, self)
      update_operative
    end
    
    def child_commands
      []
    end
    
    def new(bundle=nil)
      @bundle = bundle if bundle
      Instance.new(self, @bundle)
    end
    
    def get(iv)
      instance_variable_get(:"@#{iv.to_s}")
    end
    
    def inspect
      "#<ShellCommand: #{@name}>"
    end
    
    class Instance
      def initialize(shell_meta_command, bundle=nil)
        @shell_meta_command = shell_meta_command
        @bundle = bundle
      end
      
      def clean_script(shell_script)
        shell_script.gsub(/^#!\/usr\/bin\/env ruby (.*)$/, "#!/usr/bin/env ruby")
      end
      
      def input_type
        @shell_meta_command.input_type
      end
      
      def fallback_input_type
        @shell_meta_command.fallback_input_type
      end
      
      def output_type
        @shell_meta_command.output_type
      end
      
      def pass?
        false
      end
      
      def record?
        true
      end

      def do(opts={})
        Executor.new(self, opts).execute
      end
      
      def execute(input)
        if !@bundle
          if current_scope = Redcar.doc.cursor_scope
            App.log.info "current_scope #{current_scope.name}"
            # puts "current_pattern #{current_scope.pattern.name}"
            @bundle = Bundle.find_bundle_with_grammar(current_scope.pattern.grammar)
          end
        end
        App.set_environment_variables(@bundle)
        tf = Tempfile.new("shellcommand")
        tf.puts clean_script(shell_script)
        File.chmod(0770, tf.path)
        output, error = nil, nil
        App.log.info shell_command(tf)
        tf.close
        status = Open4.popen4(shell_command(tf)) do |pid, stdin, stdout, stderr|
          stdin.write(input)
          App.log.info "input: #{input ? input[0..300].inspect : "nil"}"
          stdin.close
          until stdout.eof?
            output = stdout.read
          end
          App.log.info "output: #{output.inspect}"
          error = stderr.read
        end
        @status = status.exitstatus
        App.log.info "command status: #{status.exitstatus}"
        unless error.blank?
          App.log.info "shell command failed with error:"
          App.log.info error
        end
        output
      end
      
      def shell_script
        @shell_meta_command.shell_script
      end
      
      def shell_command(temp_file)
        if shell_script[0..1] == "#!" and shell_script.split("\n").first !~ /#!\/bin\/sh/
          "ruby #{temp_file.path}"
        else
          "/bin/bash #{temp_file.path}"
        end
      end
      
      def self.inspect
        "<# ShellCommand(#{get(:scope)}) #{name}>"
      end
    end
  end
end
