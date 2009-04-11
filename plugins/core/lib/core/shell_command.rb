
module Redcar
  class ShellMetaCommand
    attr_accessor :tm_uuid, :bundle, :shell_script, :name
    
    def new
      ShellCommandInstance.new(self)
    end
  end

  class ShellCommandInstance
    def initialize(shell_meta_command)
      @shell_meta_command = shell_meta_command
    end
    
    def clean_script(shell_script)
      shell_script.gsub(/^#!\/usr\/bin\/env ruby (.*)$/, "#!/usr/bin/env ruby")
    end
    
    def do(opts={})
      Executer.new(self, opts).execute
    end
    
    def execute(input)
      if current_scope = Redcar.doc.cursor_scope
        App.log.info "current_scope #{current_scope.name}"
        # puts "current_pattern #{current_scope.pattern.name}"
        bundle = Bundle.find_bundle_with_grammar(current_scope.pattern.grammar)
      end
      App.set_environment_variables(bundle)
      File.open("#{Redcar::ROOT}/cache/tmp.command", "w") {|f| f.puts clean_script(shell_script)}
      File.chmod(0770, "#{Redcar::ROOT}/cache/tmp.command")
      output, error = nil, nil
      App.log.info shell_command
      status = Open4.popen4(shell_command) do |pid, stdin, stdout, stderr|
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
    
    def shell_command
      if shell_script[0..1] == "#!" and shell_script.split("\n").first !~ /#!\/bin\/sh/
        "ruby #{Redcar::ROOT}/cache/tmp.command"
      else
        "/bin/bash #{Redcar::ROOT}/cache/tmp.command"
      end
    end
    
    def self.inspect
      "<# ShellCommand(#{get(:scope)}) #{name}>"
    end
    
    #    def self.to_s
    #      inspect
    #    end
  end
end
