
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
        puts "         --no-window  Don't force opening a window on Redcar startup"
        puts "     --home-dir=PATH  Use the specified directory as Redcar home directory"
        puts "                  -w  Open the specified files and wait until they are closed"
        puts "          -l[NUMBER]  Open a specified file at line NUMBER. Multiple comma-seperated args for multiple files are allowed."
        puts "          --show-log  Print Redcar's log to stdout"
        puts "   --log-level=LEVEL  Set the log level to LEVEL (default is info, options are debug, info, warn, error)"
        puts "         --no-splash  Do not show the splash screen on startup"
        #puts "To associate with right click in windows explorer:"
        #puts
        #puts "  C:> redcar --associate_with_any_right_click"
        #puts
        exit
      end
    end
  end
end
