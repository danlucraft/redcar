module Redcar
  # Cribbed from ruby-processing. Many thanks!
  class Runner
    # Trade in this Ruby instance for a JRuby instance, loading in a 
    # starter script and passing it some arguments.
    # If --jruby is passed, use the installed version of jruby, instead of 
    # our vendored jarred one (useful for gems).
    def spin_up(args="")
      bin = File.expand_path(File.join(File.dirname(__FILE__), %w{.. .. bin redcar}))
      jruby_complete = File.expand_path(File.join(Redcar.asset_dir, "jruby-complete-1.5.2.jar"))
      unless File.exist?(jruby_complete)
        puts "\nCan't find jruby jar at #{jruby_complete}, did you run 'redcar install' ?"
        exit 1
      end
      ENV['RUBYOPT'] = nil # disable other native args
      
      # unfortuanately, ruby doesn't support [a, *b, c]
      command = ["java"]
      command.push(*java_args)
      command.push("-Xmx500m", "-Xss1024k", "-Djruby.memory.max=500m", "-Djruby.stack.max=1024k", "-cp", jruby_complete, "org.jruby.Main")
      command.push "--debug" if debug_mode?
      command.push(bin)
      command.push(*cleaned_args)
      command.push("--no-sub-jruby", "--ignore-stdin")
      command.push(*args)
      
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
      
      if ARGV.include?("--quick")
        str.push "-d32 -client"
      end
      
      str
    end
  end
end
