
Gem.post_install_hooks << lambda do |gem|
  bindir = Gem.bindir(gem.gem_home)
  File.open(bindir + "/redcar", "w") do |f|
    cmd = Redcar::Runner.command(gem.instance_variable_get("@gem_dir") + "/bin/redcar")
    f.puts <<-SH
#{cmd} "$@"
    SH
  end
end

module Redcar
  class Runner

    def self.command(bin)
      # TODO: Windows XP updates
      # if [:windows].include?(Redcar.platform)
      #   bin = "\"#{bin}\""
      # end

      command = [Config::CONFIG["bindir"] + "/jruby"]
      command.push(*java_args)
      # command.push("-J-Xbootclasspath/a:#{jruby_complete}")
      command.push("-J-Dfile.encoding=UTF8", "-J-Xmx320m", "-J-Xss1024k", "-J-Djruby.memory.max=320m", "-J-Djruby.stack.max=1024k")
      command.push(bin)
      command.push("--no-sub-jruby", "--ignore-stdin")
      command.push "--start-time=#{$redcar_process_start_time.to_i}"
      # command.push "--debug" if debug_mode?
      # command.push(*cleaned_args)
      # command.push(*args)
      command.join(" ")
    end
    
    def self.cleaned_args
      # We should never pass --fork to a subprocess
      result = ARGV.find_all {|arg| arg != '--fork'}.map do |arg|
        if arg =~ /--(.+)=(.+)/
          "--" + $1 + "=\"" + $2 + "\""
        else
          arg
        end
      end
      result.delete("install")
      result
    end
    
    def self.debug_mode?
      ARGV.include?("--debug")
    end
    
    def self.java_args
      str = []
      if Config::CONFIG["host_os"] =~ /darwin/
        str.push "-J-XstartOnFirstThread"
      end
      
      if ARGV.include?("--load-timings")
        str.push "-J-Djruby.debug.loadService.timing=true"
      end

      str.push "-J-d32" if JvmOptionsProbe.d32
      str.push "-J-client" if JvmOptionsProbe.client
      
      str
    end

    class JvmOptionsProbe
      def self.redirect
        @redirect ||= "> /dev/null 2>&1" # TODO: fix for windows
      end
      
      def self.d32
        @d32 ||= system("java -d32 #{redirect}")
      end
      
      def self.client 
        @client ||= system("java -client #{redirect}")
      end
    end
  end
end
