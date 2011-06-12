module Redcar
  # Cribbed from ruby-processing. Many thanks!
  class Runner
    def run
      forking = ARGV.include?("--fork") and ARGV.first != "install"
      no_runner = ARGV.include?("--no-sub-jruby")
      jruby = Config::CONFIG["RUBY_INSTALL_NAME"] == "jruby"
      osx = (not [:linux, :windows].include?(Redcar.platform))
      begin
        if forking and not jruby
          # jRuby doesn't support fork() because of the runtime stuff...
          forking = false
          puts 'Forking failed, attempting to start anyway...' if (pid = fork) == -1
          exit unless pid.nil? # kill the parent process
          
          if pid.nil?
            # reopen the standard pipes to nothingness
            STDIN.reopen Redcar.null_device
            STDOUT.reopen Redcar.null_device, 'a'
            STDERR.reopen STDOUT
          end
        elsif forking and SPOON_AVAILABLE and ::Spoon.supported?
          # so we need to try something different...
          
          forking = false
          construct_command do |command|
            command.push('--silent')
            ::Spoon.spawnp(*command)
          end
          exit 0
        elsif forking
          raise NotImplementedError, "Something weird has happened. Please contact us."
        end
      rescue NotImplementedError
        puts $!.class.name + ": " + $!.message
        puts "Forking isn't supported on this system. Sorry."
        puts "Starting normally..."
      end
      
      return if no_runner
      return if jruby and not osx
      
      construct_command do |command|
        exec(command.join(" "))
      end
    end
    
    # Trade in this Ruby instance for a JRuby instance, loading in a 
    # starter script and passing it some arguments.
    # If --jruby is passed, use the installed version of jruby, instead of 
    # our vendored jarred one (useful for gems).
    def construct_command(args="")
      bin = File.expand_path(File.join(File.dirname(__FILE__), %w{.. .. bin redcar}))
      jruby_complete = File.expand_path(File.join(Redcar.asset_dir, "jruby-complete-1.6.1.jar"))
      # unless File.exist?(jruby_complete)
      #   puts "\nCan't find jruby jar at #{jruby_complete}, did you run 'redcar install' ?"
      #   exit 1
      # end
      ENV['RUBYOPT'] = nil # disable other native args

      # Windows XP updates
      if [:windows].include?(Redcar.platform)
        bin = "\"#{bin}\""
        jruby_complete = "\"#{jruby_complete}\""
      end      

      # unfortuanately, ruby doesn't support [a, *b, c]
      command = ["java"]
      command.push(*java_args)
      command.push("-Xbootclasspath/a:#{jruby_complete}")
      command.push("-Dfile.encoding=UTF8", "-Xmx320m", "-Xss1024k", "-Djruby.memory.max=320m", "-Djruby.stack.max=1024k", "org.jruby.Main")
      command.push "--debug" if debug_mode?
      command.push(bin)
      command.push(*cleaned_args)
      command.push("--no-sub-jruby", "--ignore-stdin")
      command.push(*args)
      command.push "--start-time=#{$redcar_process_start_time.to_i}"
      
      puts command.join(' ')
      yield command
    end
    
    def cleaned_args
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
    
    def debug_mode?
      ARGV.include?("--debug")
    end
    
    def java_args
      str = []
      if Config::CONFIG["host_os"] =~ /darwin/
        str.push "-XstartOnFirstThread"
      end
      
      if ARGV.include?("--load-timings")
        str.push "-Djruby.debug.loadService.timing=true"
      end

      str.push "-d32" if JvmOptionsProbe.d32
      str.push "-client" if JvmOptionsProbe.client
      
      str
    end

    class JvmOptionsProbe
      def self.redirect
        @redirect ||= "> #{Redcar.null_device} 2>&1"
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
