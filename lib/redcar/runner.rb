module Redcar
  # Cribbed from ruby-processing. Many thanks!
  class Runner
    # Trade in this Ruby instance for a JRuby instance, loading in a 
    # starter script and passing it some arguments.
    # If --jruby is passed, use the installed version of jruby, instead of 
    # our vendored jarred one (useful for gems).
    def spin_up
      bin = "#{File.dirname(__FILE__)}/../../bin/redcar"
      jruby_complete = File.expand_path(File.join(File.dirname(__FILE__), "..", "jruby-complete-1.5.1.jar"))
      unless File.exist?(jruby_complete)
        puts "\nCan't find jruby jar at #{jruby_complete}, did you run 'redcar install' ?"
        exit 1
      end
      ENV['RUBYOPT'] = nil # disable other native args
      command = "java #{java_args} -Xmx500m -Xss1024k -Djruby.memory.max=500m -Djruby.stack.max=1024k -cp \"#{jruby_complete}\" org.jruby.Main #{"--debug" if debug_mode?} \"#{bin}\" #{cleaned_args} --no-sub-jruby --ignore-stdin"
      puts command
      exec(command)
    end
    
    def cleaned_args
      # We should never pass --fork to a subprocess
      ARGV.find_all {|arg| arg != '--fork'}.map do |arg|
        if arg =~ /--(.+)=(.+)/
          "--" + $1 + "=\"" + $2 + "\""
        else
          arg
        end
      end.join(' ')
    end
    
    def debug_mode?
      ARGV.include?("--debug")
    end
    
    def java_args
      if Config::CONFIG["host_os"] =~ /darwin/
        "-XstartOnFirstThread"
      else
        ""
      end
    end
  end
end
