
module Redcar
  
  class Usage
    def version_string
      str = "Redcar #{Redcar::VERSION} ( #{RUBY_PLATFORM} )"
      puts str
    end
    
    def version_requested
      if ARGV.include?("-v")
        puts "Redcar #{Redcar::VERSION}"
        exit
      end
    end

    def help_requested
      if ARGV.include?("-h") or ARGV.include?("--help")
        puts
        puts "Usage: redcar [OPTIONS] [FILE|DIR]*"
        puts
        puts " --multiple-instance  Don't attempt to open files and dirs in an already running instance"
        puts "             --debug  JRuby debugging mode: activates the profiling commands in the Debug menu"
        puts "--untitled-file=PATH  Open the given file as an untitled tab."
        puts "      --ignore-stdin  Ignore stdin."
        puts "              --fork  Detach from the console."
        #puts "To associate with right click in windows explorer:"
        #puts
        #puts "  C:> redcar --associate_with_any_right_click"
        #puts
        exit
      end
    end
  end
end
